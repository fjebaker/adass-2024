#set page(width: 2160pt, height: 3840pt, margin: (2.0cm), fill: orange.lighten(90%))

#let STROKE_WIDTH = 6pt

// colours
#let COLOR_GREEN = rgb("#389826")
#let COLOR_RED = rgb("#CB3C33")
#let COLOR_PURPLE = rgb("#9558B2")
#let COLOR_BLUE = rgb("#4063D8")

#set text(size: 34pt)
#set par(leading: 18pt, justify: true)

#show heading.where(level: 1): h => [
  #set text(size: 42pt, weight: "black")
  #h
]

#show raw: b => [
  #set text(size: 24pt)
  #block(
    fill: orange.lighten(94%),
    inset: (top: 0.5cm, bottom: 0.5cm, left: 0.4cm, right: 0.4cm),
    radius: 0.5cm,
    stroke: 2pt + black,
    width: 100%,
    [ #b ]
  )
]

#let secblock(body, fill: luma(230), stroke: 0pt) = block(
  fill: fill.lighten(80%),
  inset: 1cm,
  radius: 1cm,
  width: 100%,
  stroke: fill + 6pt,
  below: 1cm,
  above: 1cm,
)[
  #body
]

#{
  set align(left)
  set text(weight: "black")
  set par(leading: 0pt)
  block(
    inset: (left: 0cm, right: 1cm),
    grid(
      columns: (50%, 1fr),
      column-gutter: 1cm,
      text(size: 130pt)[SpectralFitting.jl:],
      [
        #set par(leading: 20pt)
        #text(size: 74pt)[a fresh approach to spectral fitting]
      ]
    )
  )

  set text(weight: "regular")
  v(-6cm)
  text(size: 40pt)[
    *Fergus Baker*#super("1"), Andrew Young#super("1"), Paul Barrett#super("2"), Eric Schlegel#super("3"), Joe Prendergast#super("4")
  ]
  h(1fr)
  box(inset: (top: 2.5cm), image("./logos/logo.svg", height: 7cm), height: 7cm)
  box(inset: (top: 1.5cm), image("./logos/UoB_CMYK_24.svg", height: 8cm), height: 7cm)
}

#let introduction = secblock(fill: COLOR_BLUE)[
  = The need for new tools
  Tools must be *flexible* and *extensible* to accommodate the needs of modern
  research. Current spectral fitting solutions lack these aspects, with brittle
  codebases, dated architectures, and monolithic distributions. The best ideas
  that get you from A to B are not necessarily the best ideas to get you from B
  to C. Frequentist thinking has been largely replaced with *Bayesian
  approaches*, and even within the Bayesian approach, the *standard techniques
  are shifting* from Monte-Carlo Markov chains (MCMC) to normalising flows.
  SpectralFitting is designed to be able to keep up with the changes in
  optimization approaches, visualisation preferences, and statistical theory
  using a series of simple APIs.

  In the era of ever higher resolution and high volume astronomical data, the
  *computational performance* of models are crucial to avoid bottlenecks in a
  fitting. Modern spectral fitting tools *must take advantage* of the massively
  *parallel compute* available on modern hardware. As SpectralFitting is
  written in the Julia programming language, the tool is portable and scalable
  over a wide variety of architectures and hardware.

]

#let modular_design = secblock(fill: COLOR_RED)[
  = Modules and FFI
  *foreign function interface (FFI)*
  Cross-compiled XSPEC model library, model distribution,
  Julia Package manager for distribution
  - Illustration of how we deliver models

  #image("./figs/architecture.svg", width: 100%)
]

#let models = secblock(fill: COLOR_GREEN)[
  = Differentiable models
  Julia has excellent support for *automatic differentiation (AD)*. We can calculate derivatives on the forward (or backward) pass through the model for use in the *numerical optimizer*, enabling advanced optimization algorithms.
  ```julia
  Base.@kwdef struct MyModel{T} <:
      AbstractSpectralModel{T,Additive}
      "Normalisation"
      K::T = FitParam(1.0)
      "Some Parameter"
      p1::T = FitParam(3.0, lowerbound = 0.0)
  end
  SpectralFitting.invoke!(out, domain, m::MyModel)
      # model implementation here
  end
  # calculate derivatives via Automatic Differentiation
  gradient(
    x -> invokemodel(domain, MyModel(;p1 = x)),
    3.0
  )
  ```
  The number abstraction allows us to also use packages like Measurements.jl or Unitful.jl to propagate uncertainties or units seamlessly through the package.
]

#let fits = secblock(fill: COLOR_PURPLE)[
  = Flexible fitting
  #grid(columns: (42%, 1fr),
    [
    SpectralFitting already vendors *many mathematical optimizers*, including Levenberg-Marquadt least-squares, Nelder-Mead, Broyden-Fletcher-Goldfarb-Shanno, and allows users to use probabilistic frameworks, like Turing.jl, with ease. *Simultaneous fits* can be performed, with *parameter binding*, minimizing $chi^2$ or the Cash statistic, or even a *user-defined likelihood function*. Access to AD make these performant and accurate.
    ```julia
    prob = FittingProblem(model1 => data1, model2 => data2)
    # bind parameters by their symbols
    bind!(prob, 1 => :K, 2 => :a)
    # one line changes to use different minimizations
    result = fit(prob, Levenberg-Marquadt())
    result = fit(prob, NelderMead(); stat = Cash())
    result = fit(prob, BFGS())
    ```
  ]
  )
]

#let performance = secblock(fill: COLOR_RED)[
  = Performance
  SpectralFitting is designed to take *full advantage of multi-core, parallel execution*, and even *GPU offloading*.
]

#let surrogates = secblock(fill: COLOR_BLUE)[
  = Surrogates and Machine Learning
  Models that are too slow to be effectively fitted can be wrapped as a
  *surrogate model*. Surrogates are *machine learned* alternatives for the
  model component, which can be trained to replicate the output space of the
  model, or used in *hybrid* to learn the fit statistic and help *optimize the
  fit*.
]

#let conclusion = secblock(fill: COLOR_GREEN)[
  = Conclusion
]

#set columns(gutter: 1cm)

#grid(columns: (44%, 1fr),
  column-gutter: 1cm, row-gutter: 1cm,
  [
    #text(size: 38pt)[
      #box(image("./logos/github-mark.svg"), height: 1em) #link("https://github.com/fjebaker/SpectralFitting.jl/")
    ]
    = Abstract
    We present SpectralFitting, an open-source, work-in-progress package for the
    Julia programming language that aims to modernise the spectral fitting process.
    Our approach is to create modular, lazily loaded, strictly reproducible and
    easily distributable software that can fully utilize available computational
    resources. We aim to unite existing analysis tooling across the electromagnetic
    spectrum, to provide a single tool that can fit large volumes of
    multi-wavelength data, with a choice of optimization algorithms and hardware
    acceleration. We welcome collaboration and comments.
    #models
  ],
  [
    #introduction
    #modular_design
  ]
)

#fits

#columns(2)[
  #performance

  #colbreak()

  #surrogates
  #conclusion
]

#secblock(stroke: STROKE_WIDTH + black)[
  Footer
]
