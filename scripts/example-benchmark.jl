using SpectralFitting
using XSPECModels
using BenchmarkTools
using Makie, CairoMakie


energy = collect(range(1e-3, 10.0, 10_000))

nums = collect(1:10)

xspec_infos = map(nums) do i
    @info i
    model = sum(XS_Gaussian() for i = 1:i)
    flux = SpectralFitting.allocate_model_output(model, energy)
    info = @benchmark invokemodel!($flux, $energy, $model)
end
infos = map(nums) do i
    @info i
    model = sum(GaussianLine() for i = 1:i)
    flux = SpectralFitting.allocate_model_output(model, energy)
    info = @benchmark invokemodel!($flux, $energy, $model)
end

xspec_times = [median(i.times) for i in xspec_infos]
times = [median(i.times) for i in infos]

xspec_std = [std(i.times) for i in xspec_infos]
stds = [std(i.times) for i in infos]

begin
    fig = Figure(size = (400, 300))
    ax = Axis(
        fig[1, 1],
        ylabel = "Evaluation time (ms)",
        xlabel = "Number of Gaussian components",
        title = "Naive performance (lower is better)",
    )

    Makie.scatterlines!(ax, nums, xspec_times ./ 1e6, label = "XSPEC")
    Makie.scatterlines!(ax, nums, times ./ 1e6, label = "SpectralFitting")

    axislegend(ax, position = :lt)

    Makie.save("benchmark-comparison.svg", fig)
    fig
end
