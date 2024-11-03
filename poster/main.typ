#set page(width: 2160pt, height: 3840pt, margin: (2.0cm), fill: orange.lighten(90%))

#let STROKE_WIDTH = 6pt

#let SPACING = 0.6cm

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
  inset: SPACING,
  radius: SPACING,
  width: 100%,
  stroke: fill + 6pt,
  below: SPACING,
  above: SPACING,
)[
  #body
]

#{
  set align(left)
  set text(weight: "black")
  set par(leading: 0pt)
  block(
    inset: (left: 0cm, right: SPACING),
    grid(
      columns: (50%, 1fr),
      column-gutter: SPACING,
      text(size: 130pt)[SpectralFitting.jl:],
      [
        #set par(leading: 20pt)
        #text(size: 74pt)[a fresh approach to spectral fitting]
      ]
    )
  )

  set text(weight: "regular")
  v(-0.6cm)
  text(size: 40pt)[
    #block(width: 80%)[
    *Fergus Baker*#super[1,$dagger$], Andrew Young#super("1"), Gloria Raharimbolamena#super("1"), Paul Barrett#super("2"), \
    Eric Schlegel#super("3"), Joe Prendergast#super("4")
    ]
  ]
  v(-8.3cm)
  h(1fr)
  box(inset: (top: 1.5cm), image("./logos/logo.svg", height: 7cm), height: 7cm)
  box(inset: (top: 0.5cm), image("./logos/UoB_CMYK_24.svg", height: 8cm), height: 7cm)
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
  *computational performance* of models is crucial to avoid bottlenecks in a
  fitting. Modern spectral fitting tools *must take advantage* of the massively
  *parallel architectures* available on modern hardware. As SpectralFitting is
  written in the Julia programming language, the tool is portable and scalable
  over a wide variety of machines.
]

#let modular_design = secblock(fill: COLOR_RED)[
  = Modules and FFI
  The modular design of SpectralFitting, along with Julia's *foreign function
  interface (FFI)*, make existing models in other programming language
  available to the user. We have cross-compiled and wrapped the entire XSPEC
  model library with BinaryBuilder.jl for lazily-loaded distribution. We use
  the built-in Julia *package manager Pkg.jl* with a domain-specific registry
  to distribute user models and data.
  #v(0.25cm)
  #v(-1.7em)
  #image("./figs/architecture.svg", width: 100%)
  #v(-0.052em)
  #v(0.25cm)
  SpectralFitting has *four principle APIs*. Each is designed to be pluggable
  and permit down-stream packages to *alter and extend* the behaviour of the
  package in a robust way.
]

#let models = secblock(fill: COLOR_GREEN)[
  = Differentiable models
  Julia has excellent support for *automatic differentiation (AD)*, enabling the evaluation of derivatives in tandem with the model. The derivative information can be used by the *numerical optimizer*, permitting the use of advanced optimization algorithms, and reducing inference time.
  #v(-0.8cm)
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
  #v(-0.8cm)
  The Julia Number abstraction allows us to also use the *Measurements.jl* or *Unitful.jl* packages to propagate uncertainties or units seamlessly.
]

#let fits = secblock(fill: COLOR_PURPLE)[
  #grid(
    columns: (41%, 1fr),
    column-gutter: SPACING,
    [
    #align(center)[
      #rect(
        radius:SPACING,
        width: 100%,
        fill: white,
        inset:5mm,
        stroke: black + 2pt,
        image("./figs/xrism-obs-example.svg", width:90%)
      )
    ]
    #v(-0.8cm)
    ```julia
    prob = FittingProblem(model1 => data1, model2 => data2)
    # bind parameters by their symbols
    bind!(prob, 1 => :K, 2 => :a)
    # one line changes to use different minimizations
    result = fit(prob, LevenbergMarquadt())
    result = fit(prob, NelderMead(); stat = Cash())
    result = fit(prob, BFGS())
    ```
    ],
    [
    = Flexible fitting
    SpectralFitting is compatible with *many mathematical optimizers*,
    including Levenberg-Marquadt least-squares, Nelder-Mead,
    Broyden-Fletcher-Goldfarb-Shanno, and allows users to use probabilistic
    frameworks, such as Turing.jl, with ease. *Simultaneous fits* can be
    performed, with *parameter binding*, minimizing $chi^2$ or the Cash
    statistic, or even a *user-defined likelihood function*.
    #v(-0.8cm)
    #align(center)[
      #rect(
        radius:SPACING,
        width: 100%,
        fill: white,
        inset:5mm,
        stroke: black + 2pt,
        grid(columns: (50%, 1fr),
          column-gutter: SPACING,
          [
            #v(1cm)
            #image("./figs/mcmc-fit.svg", width:100%)
          ],
          image("./figs/mcmc-example.svg", width:94%),
        )
      )
    ]

    ],
  )
]

#let performance = secblock(fill: COLOR_RED)[
  = Performance
  SpectralFitting is designed to take *full advantage of multi-core, parallel execution*, and even *GPU offloading*. The *multiple dispatch* paradigm in Julia allows simple models to have contextual implementations, that are *just-in-*
  #v(-0.7em)
  #grid(
    columns: (58%, 1fr),
    column-gutter: SPACING,
    [
      #align(center)[
      #rect(
        radius:SPACING,
        width: 100%,
        fill: white,
        inset:5mm,
        stroke: black + 2pt,
        image("./figs/benchmark-comparison.svg", width:100%)
      )
    ]
  ], [
     *time (JIT)* compiled. This means even naive implementations of simple
     models, such as a Gaussian distribution, can *outperform* the XSPEC
     implementations by a factor of 3 on a single thread. With AD, the
     *parameter inference time* consistently outperforms the inference of
     other spectral fitting solutions.
  ])
]

#let surrogates = secblock(fill: COLOR_GREEN)[
  = Surrogates and Machine Learning
  Surrogate spectral models are *machine learned* proxies for a model
  component, useful when performance is bottlenecked, or differentiability is
  needed. Surrogates are trained to replicate the output space of a model, or
  can be used in *amalgamation (hybrid) with the underlying model* to learn the
  manifold of the *fit statistics* and help *optimize the fit*.

  #v(-0.8cm)
  #align(center)[
      #rect(
        radius:SPACING,
        width: 100%,
        fill: white,
        inset:5mm,
        stroke: black + 2pt,
        image("./figs/surrogate-example.png", width: 75%)
      )
  ]
  #v(-0.8cm)

  Surrogates created from XSPEC models can give *over a 1000x speedup* without hyperparameter tuning, and suffer *less than a 1% error* in the reproduction.
]

#let conclusion = secblock(fill: COLOR_BLUE)[
  = Conclusion
  We invite *collaboration and use-cases* for SpectralFitting. The state of the project and progress towards different goals are described in more detail in our documentation, which can be found alongside our *GitHub repository* (link at the top of the poster). We encourage use, bug reports, and feedback.

  SpectralFitting is open-source under the GPL-3.0 license.
]

#set columns(gutter: SPACING)

#grid(columns: (44%, 1fr),
  column-gutter: SPACING, row-gutter: SPACING,
  [
    #v(-1cm)
    #text(weight: "black", size: 38pt, fill: COLOR_BLUE)[
      #box(inset: (left: 1cm), image("./logos/github-mark.svg"), height: 1em) #link("https://github.com/fjebaker/SpectralFitting.jl/") \
      #box(inset: (left: 1cm), text(fill: black)[🖂], height: 1em) #super[#text(fill: black)[$dagger$]]#link("fergus.baker@bristol.ac.uk")
    ]
    #v(-1.5cm)
    = Abstract
    We present SpectralFitting, an *open-source*, work-in-progress package for the
    *Julia programming language* that aims to modernise the spectral fitting process.
    Our approach is to create modular, lazily-loaded, strictly reproducible and
    easily distributable software that can fully utilize available computational
    resources. We aim to *unite existing analysis tooling* across the electromagnetic
    spectrum, to provide a single tool that can fit large volumes of
    multi-wavelength data, with a choice of optimization algorithms and hardware
    acceleration. Our initial focus is on X-ray data. We welcome collaboration and comments.
    #v(0.2cm)
    #models
  ],
  [
    #v(-1.0cm)
    #introduction
    #modular_design
  ]
)

#fits

#grid(
  columns: (55%, 1fr),
  column-gutter: SPACING,
  row-gutter: SPACING,
  [
    #performance
    #conclusion
  ],
  [
    #surrogates
    #v(SPACING / 2)
    #grid(
      columns: (30%, 1fr),
      [
        #set align(center)
        #set align(horizon)
        #image("./figs/adass-github.svg", width: 65%)
      ],
      [
        #set text(size: 30pt)
        For the source code for this poster, including all figures, scan the QR code or visit: \
        #text(fill: COLOR_BLUE)[#link("https://github.com/fjebaker/adass-2024/")] \
        Find more information about SpectralFitting at the same place.
      ]
    )
    #v(-1cm)
  ]

)

// #secblock(stroke: STROKE_WIDTH + black)[
#v(-0.5cm)
  #text(size: 28pt)[
    *Affiliations:*\
    #super("1")University of Bristol, #super("2")The George Washington University, #super("3")University of Texas in San Antonio, #super("4")American University
  ]
// ]
