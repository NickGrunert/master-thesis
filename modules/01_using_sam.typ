#import "@preview/subpar:0.2.0"

#let sam() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )



    = SAM
    This is text


    == Input Prompting Strategies

    === Random Strategy

    === Center Strategy
    Code is moved to @code:center

    === Combined Strategy
  ]

  pagebreak()
}