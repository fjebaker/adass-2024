using SpectralFitting
using Makie
using CairoMakie
using Printf


DATADIR = "xrism"
spec_path = joinpath(DATADIR, "xa_merged_p0px1000_Hp.pi")
response_path = joinpath(DATADIR, "xa_merged_p0px1000_HpS.rmf")
ancillary_path = joinpath(DATADIR, "rsl_standard_GVclosed.arf")
data = OGIPDataset(spec_path, response = response_path, ancillary = ancillary_path)

normalize!(data)
mask_energies!(data, 6.45, 6.65)

begin
    model =
        GaussianLine(μ = FitParam(6.51), σ = FitParam(0.1), K = FitParam(0.1)) +
        PowerLaw(a = FitParam(0.0, frozen = true)) +
        GaussianLine(μ = FitParam(6.58)) +
        GaussianLine(μ = FitParam(6.55)) +
        GaussianLine(μ = FitParam(6.57)) +
        GaussianLine(μ = FitParam(6.52))
    model.σ_1.value = 1e-2
    model.σ_2.value = 1e-2
    model.σ_3.value = 1e-2
    model.σ_4.value = 1e-2
end

domain = collect(range(6.45, 6.65, 300))

flux = invokemodel(domain, model)
plot(domain[1:end-1], flux)

prob = FittingProblem(model => data)

result = SpectralFitting.fit!(prob, LevenbergMarquadt())
model

layout = SpectralFitting.with_units(
    SpectralFitting.preferred_support(model),
    SpectralFitting.preferred_units(data, ChiSquared()),
)
xfm = SpectralFitting.objective_transformer(layout, data)
domain = make_model_domain(layout, data)

begin
    f0 = xfm(domain, invokemodel(domain, model.a5 + model.a6))

    f1 = xfm(domain, invokemodel(domain, model.a1))
    f2 = xfm(domain, invokemodel(domain, model.a2))
    f3 = xfm(domain, invokemodel(domain, model.a3))
    f4 = xfm(domain, invokemodel(domain, model.a4))

    flux = xfm(domain, invokemodel(domain, model))
end

begin
    palette = Iterators.Stateful(Iterators.Cycle(Makie.wong_colors()))

    fig = Figure(size = (500, 340))
    ga = fig[1, 1] = GridLayout()
    ax = Axis(ga[1, 1], ylabel = "Flux (counts s⁻¹ keV⁻¹)", title = "Perseus_CAL1")
    ax2 = Axis(ga[2, 1], xlabel = "Energy (keV)", ylabel = "Residual")

    pdomain = SpectralFitting.plotting_domain(data)
    obj = SpectralFitting.make_objective(layout, data)

    xerr = SpectralFitting.bin_widths(data) ./ 2
    yerr = sqrt.(SpectralFitting.make_objective_variance(layout, data))

    c = popfirst!(palette)

    data_points = errorbars!(ax, pdomain, obj, yerr, whiskerwidth = 3, color = c)
    errorbars!(ax, pdomain, obj, xerr, direction = :x, color = c)

    elem_1 = [MarkerElement(color = c, marker = 'x', markersize = 15)]

    comps = [model.a1, model.a2, model.a3, model.a4]
    for (i, f) in enumerate([f1, f2, f3, f4])
        c = popfirst!(palette)
        lines!(ax, pdomain, vec(f .+ f0), color = c, linewidth = 2.0)
        band!(ax, pdomain, vec(f0), vec(f .+ f0), color = c, alpha = 0.5)
        vlines!(ax, [comps[i].μ.value], color = c, linestyle = :dash)
    end


    lines!(ax, pdomain, vec(flux), color = :red, linewidth = 2.0)
    elem_2 = [LineElement(color = :red, linewidth = 2.0)]

    resids = @. (obj - flux) / yerr

    stairs!(ax2, pdomain, vec(resids), step = :center)
    band!(ax2, pdomain, zeros(length(resids)), vec(resids), alpha = 0.5)

    rowsize!(ga, 1, Relative(3 / 4))
    hidexdecorations!(ax, grid = false)
    linkxaxes!(ax, ax2)
    xlims!(ax2, 6.46, 6.64)

    _stat = Printf.@sprintf("%.1f", result.χ2)
    Legend(
        ga[1, 1],
        [elem_1, elem_2],
        ["Observation", L"\chi^2=%$(_stat)"],
        tellheight = false,
        tellwidth = false,
        halign = 0.05,
        valign = 0.95,
    )
    fig

    Makie.save("./xrism-obs-example.svg", fig)
    fig
end
