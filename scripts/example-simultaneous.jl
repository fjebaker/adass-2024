using SpectralFitting
using Printf
using Plots
using Turing
using CairoMakie
using PairPlots

data_path = "data"

function prepare!(ds, min, max)
    regroup!(ds)
    drop_bad_channels!(ds)
    mask_energies!(ds, min, max)
    subtract_background!(ds)
    normalize!(ds)
    ds
end
function prepare_xmm(spec, back, rmf, arf)
    ds = XmmData(XmmEPIC(), spec, background = back, response = rmf, ancillary = arf)
    prepare!(ds, 3.0, 10.0)
end
function prepare_nustar(data_path, obsid, fpm)
    ds = NuStarData(joinpath(data_path, "nu$(obsid)$(fpm)01_sr_min20.pha"))
    prepare!(ds, 3.0, 50.0)
end

xmm_data = []
for i = 2:4
    spec = joinpath(data_path, "PN_spectrum_grp_0693781$(i)01_S003_total.fits")
    back = joinpath(data_path, "PNbackground_spectrum_0693781$(i)01_S003_total.fits")
    rmf = joinpath(data_path, "PN_0693781$(i)01_S003_total.rmf")
    arf = joinpath(data_path, "PN_0693781$(i)01_S003_total.arf")
    push!(xmm_data, prepare_xmm(spec, back, rmf, arf))
end

begin
    model =
        PowerLaw(a = FitParam(0.3)) +
        GaussianLine(K = FitParam(0.02), μ = FitParam(6.4), σ = FitParam(0.05))
    model.K_2.value = 1.7


    sim_data1 = simulate(model, xmm_data[1], exposure_time = 1, seed = 5)
    model.K_1.value = 0.03
    model.K_2.value = 3.0
    sim_data2 = simulate(model, xmm_data[2], exposure_time = 2, seed = 7)

    model.K_1.value = 0.05
    model.K_2.value = 2.3
    sim_data3 = simulate(model, xmm_data[3], exposure_time = 1, seed = 9)
end

model = PowerLaw() + GaussianLine()
prob = FittingProblem(model => sim_data1, model => sim_data2, model => sim_data3)
bind!(prob, :μ_1, :σ_1, :a_1)
details(prob)

result = SpectralFitting.fit(prob, LevenbergMarquadt())

@model function mcmc_model(domain, objective, variance, f)
    K1 ~ Normal(0.02, 0.02)
    μ1 ~ Normal(6.4, 0.1)
    σ1 ~ Normal(0.05, 0.1)

    K2 ~ Normal(1.7, 0.1)
    a1 ~ Normal(0.3, 0.1)
    pred = f(domain, [K1, μ1, σ1, K2, a1])
    return objective ~ MvNormal(pred, variance)
end

begin
    all_chains = map((sim_data1, sim_data2, sim_data3)) do d
        config = FittingConfig(FittingProblem(model => d))
        mm = mcmc_model(
            config.model_domain,
            config.objective,
            sqrt.(config.variance),
            SpectralFitting._f_objective(config),
        )
        sample(mm, NUTS(), 1000)
    end
end

begin
    fig = Figure(size = (500, 400))
    ax = Axis(
        fig[1, 1],
        title = "Simultaneous fit",
        xlabel = "Energy (keV)",
        ylabel = "Flux (counts s⁻¹ keV⁻¹)",
    )
    p = Plots.plot(sim_data1)

    palette = Iterators.Stateful(Iterators.Cycle(Makie.wong_colors()))
    plts = map(enumerate([sim_data1, sim_data2, sim_data3])) do ((i, d))
        c = popfirst!(palette)

        p_domain = SpectralFitting.plotting_domain(d)
        layout = SpectralFitting.with_units(
            SpectralFitting.preferred_support(d),
            SpectralFitting.preferred_units(d, ChiSquared()),
        )
        obj = SpectralFitting.make_objective(layout, d)
        var = SpectralFitting.make_objective_variance(layout, d)
        xerr = SpectralFitting.bin_widths(d) ./ 2

        pts = errorbars!(ax, p_domain, obj, sqrt.(var), color = c)
        errorbars!(ax, p_domain, obj, xerr, direction = :x, color = c)

        res = result[i]

        flux = invoke_result(res, res.u)
        _stat = Printf.@sprintf("%.1f", res.χ2)
        ft = lines!(ax, p_domain, flux, label = L"\chi^2 = %$_stat ", color = c)

        # MCMC uncertainty
        param_order = [:K1, :μ1, :σ1, :K2, :a1]
        params = get(all_chains[i], param_order)
        all_invokes = map(1:500) do i
            u0 = [getfield(params, s)[i] for s in param_order]
            copy(invoke_result(res, u0))
        end
        invks = reduce(hcat, all_invokes)
        v_means = vec(mean(invks, dims = 2))
        v_std = vec(std(invks, dims = 2))

        band!(ax, p_domain, v_means .- 3v_std, v_means .+ 3v_std, color = c, alpha = 0.5)

        (pts, ft)
    end

    axislegend(ax, position = :lb)

    Makie.save("mcmc-fit.svg", fig)
    fig
end

begin
    fig = Figure(size = (600, 600))
    PairPlots.pairplot(
        fig[1, 1],
        all_chains[1],
        bodyaxis = (; xgridvisible = true, ygridvisible = true),
    )
    Makie.save("mcmc-example.svg", fig)
    fig
end
