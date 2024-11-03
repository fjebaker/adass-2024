# simultaneously fit NuStar and XMM data using only Julia models in SpectralFitting
using Revise
using SpectralFitting
using Plots
using Gradus
using GradusSpectralModels
using JLD2
using CodecZlib
using CairoMakie
import PairPlots
# using Reflionx

data_path = "data"
REFLIONX_GRID_DIR = joinpath(data_path, "reflionx/grid")

function read_or_make_transfer_table(path; new = false)
    @info "Reading transfer function table from file..."
    f = jldopen(path, "r")
    table = f["table"]
    close(f)
    table
end

TRANSFER_FUNCTION_PATH = joinpath(data_path, "thin-disc-transfer-table-900.jld2")
table = read_or_make_transfer_table(TRANSFER_FUNCTION_PATH);

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

nustar_data = []
for obsid in ["60001047002", "60001047003", "60001047005"]
    for fpm in ["A", "B"]
        push!(nustar_data, prepare_nustar(data_path, obsid, fpm))
    end
end

begin
    p = plot(xmm_data[1], xscale = :log10)
    for i = 2:lastindex(xmm_data)
        plot!(p, xmm_data[i], xscale = :log10, yscale = :log10)
    end
    p
    for i = 1:lastindex(nustar_data)
        plot!(p, nustar_data[i], xscale = :log10, yscale = :log10)
    end
    plot(p, ylims = (1e-3, 2.0))
end


lp_model = LineProfile(
    x -> x^-3,
    table;
    E₀ = FitParam(6.4),
    a = FitParam(0.998, lower_limit = 0.0, upper_limit = 0.998),
    # speed up model evaluation about 3 times
    quadrature_points = 9,
    n_radii = 300,
)
lp_model.E₀.value = 6.4
lp_model.E₀.frozen = true
lp_model.rin.frozen = true
lp_model.rout.frozen = true
lp_model.rout.value = 100.0

model = PowerLaw() + AutoCache(lp_model)
# model = PowerLaw()
# model.a1.K.value = 0.0056187
# model.a1.K.frozen = true

using BenchmarkTools
domain = collect(range(0.1, 10.0, 1000))
fluxes = allocate_model_output(model, domain)

using Profile
import ProfileView

function profile_model(model)
    domain = collect(range(0.1, 10.0, 1000))
    fluxes = allocate_model_output(model, domain)

    @time for i = 1:10_00
        SpectralFitting.invokemodel!(fluxes, domain, model)
    end
    fluxes
end

@profview profile_model(model)

@btime invokemodel!($fluxes, $domain, $model)

all_data = (xmm_data...,)[1:1]
prob = FittingProblem((model => d for d in all_data)...)
bind!(prob, :a_1, :a_2, :θ_1)
# bind!(prob, :a)
details(prob)


conf = FittingConfig(prob)

result = @time fit(prob, LevenbergMarquadt())

begin
    p = plot(xmm_data[1], xscale = :log10)
    for i = 2:lastindex(xmm_data)
        plot!(p, xmm_data[i], xscale = :log10, yscale = :log10)
    end

    # for i in 1:lastindex(nustar_data)
    #     plot!(p, nustar_data[i], xscale=:log10, yscale=:log10)
    # end

    for i = 1:length(all_data)
        plot!(p, result[i])
    end

    plot(p, ylims = (1e-3, 2.0), legend = :outertopright)
end

using Turing

@model function mcmc_model(domain, objective, variance, f)
    # [0.00012655, 0.99794, 37.531, 0.011682, 1.9476]
    K ~ truncated(Normal(0.000225, 1e-4); lower = 0)
    a ~ truncated(Normal(0.997, 0.1); upper = 1, lower = -1)
    θ ~ truncated(Normal(37, 0.5); lower = 0, upper = 90)

    K2 ~ truncated(Normal(0.011682, 1e-4); lower = 0)
    a2 ~ truncated(Normal(1.9, 0.5); lower = 1)

    pred = f(domain, [K, a, θ, K2, a2])
    # pred = f(domain, [K2, a2])
    return objective ~ MvNormal(pred, sqrt.(variance))
end

config = FittingConfig(prob)
mm = mcmc_model(
    config.model_domain,
    config.objective,
    config.variance,
    # _f_objective returns a function used to evaluate and fold the model through the data
    SpectralFitting._f_objective(config),
)

chain = sample(mm, NUTS(), 5_000)

pairplot(chain)




function profile_test(n)
    for i = 1:n
        A = randn(100, 100, 20)
        m = maximum(A)
        Am = mapslices(sum, A; dims = 2)
        B = A[:, :, 5]
        Bsort = mapslices(sort, B; dims = 1)
        b = rand(100)
        C = B .* b
    end
end

using ProfileView
using Profile
Profile.clear()
@profile profile_test(1)  # run once to trigger compilation (ignore this one)
@profile profile_test(10)
Profile.print()
