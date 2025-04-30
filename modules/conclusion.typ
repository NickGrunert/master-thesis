#import "@preview/subpar:0.2.0"

#let conclusion() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Conclusion
  ]
}