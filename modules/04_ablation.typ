#import "@preview/subpar:0.2.0"

#let ablation() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Ablation Study and Algorithm Improvement

    == Impact of Hyperparameter Values

    === Clipping Values

    === Blurring Method

    === Canny Values

    == Using SAM for Base Area Detection <section:replace_clipping_by_sam>
  ]
}