using SpectralFitting, XSPECModels
using Makie, CairoMakie

energy = collect(range(0.1, 20.0, 200))
model = XS_PhotoelectricAbsorption()

flux = similar(energy)[1:end-1]

using BenchmarkTools
@benchmark invokemodel!($flux, $energy, $model)

lower_bounds = (1e-3,)
upper_bounds = (30.0,)

using Surrogates

harness = make_surrogate_harness(
    (x, y) -> RadialBasis(x, y, lower_bounds, upper_bounds),
    energy,
    model,
    lower_bounds,
    upper_bounds;
    # default is 50, but to illustrate the training behaviour we'll set this low
    seed_samples = 2,
)

# number of points the surrogate has been trained on
length(harness.surrogate.x)

# random test value
ηh_test = 22.9

model.ηH.value = ηh_test
f = invokemodel(energy, model)

f̂ = harness.surrogate([ηh_test])

sm = make_model(harness)
untrained_s_fluxes_vecs = map(p_range) do p
    sm.params[1].value = p
    display(sm)
    f = invokemodel(energy, sm)
end
untrained_s_fluxes_mat = reduce(hcat, untrained_s_fluxes_vecs)

optimize_accuracy!(harness; maxiters = 50)

length(harness.surrogate.x)

new_f̂ = harness.surrogate([ηh_test])

sm = make_model(harness)

@benchmark invokemodel!($flux, $energy, $sm)

p_range = collect(range(1.0, 30.0))

fluxes_vecs = map(p_range) do p
    model.ηH.value = p
    f = invokemodel(energy, model)
end
fluxes_mat = reduce(hcat, fluxes_vecs)

# surface(p_range, energy[1:end-1], fluxes_mat, xlabel = "ηH", ylabel = "E", zlabel = "f", title = "Model")

s_fluxes_vecs = map(p_range) do p
    sm.params[1].value = p
    display(sm)
    f = invokemodel(energy, sm)
end
s_fluxes_mat = reduce(hcat, s_fluxes_vecs)

# surface(p_range, energy[1:end-1], s_fluxes_mat, xlabel = "ηH", ylabel = "E", zlabel = "f", title = "Surrogate")

begin
    fig = Figure(size = (460, 300))
    ga = fig[1, 1] = GridLayout()
    ax1 = Axis3(
        ga[1, 1],
        title = "Base model",
        aspect = (1, 1, 1),
        azimuth = deg2rad(140),
        xlabel = "E (keV)",
        ylabel = "ηH",
        zlabel = "",
    )
    ax2 = Axis3(
        ga[1, 2],
        title = "Surrogate",
        aspect = (1, 1, 1),
        azimuth = deg2rad(140),
        xlabel = "E (keV)",
        ylabel = "ηH",
        zlabel = "",
    )

    surface!(ax1, energy[1:end-1], p_range, fluxes_mat, colormap = :batlow)
    surface!(ax2, energy[1:end-1], p_range, s_fluxes_mat, colormap = :batlow)

    zlims!(ax1, (0, 1))
    zlims!(ax2, (0, 1))

    Makie.save("surrogate-example.png", fig, dpi = 600)
    fig
end
