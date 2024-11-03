# SpectralFitting.jl: a fresh approach to spectral fitting

Source code for my ADASS 2024 poster on [SpectralFitting](https://github.com/fjebaker/SpectralFitting.jl).

You can download a copy of the poster from the [latest release]().

## Poster

The poster is compiled using [Typst](https://typst.app/). To build from source, use version 0.12 or greater, and run:
```bash
typst compile poster/main.typ
```

## Figures

The figures were generated using the scripts in `/scripts`, with some final
cosmetic tweaks to the formatting done using [Inkscape](https://inkscape.org/).
To run the scripts, follow the SpectralFitting [installation
guide](https://fjebaker.github.io/SpectralFitting.jl/dev/), then instantiate
the Julia environment in the root directory:

```julia
pkg> activate .
pkg> instantiate
```

The scripts use data from the [XRISM early
release](https://heasarc.gsfc.nasa.gov/docs/xrism/results/erdata/index.html)
for the Perseus cluster, and the instrument response files from XMM
observations. The precise XMM files used are from [Andy's Sesto
talk](https://github.com/phajy/Sesto2024). These should be unpacked and put
into a `xrism` and `data` directory respectively.

