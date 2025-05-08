#import "@preview/subpar:0.2.0"

#let conclusion() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Conclusion and Future Work

    /*
    How effective is the zero-shot learning capability of #abr("SAM") in accurately segmenting building roof details, particularly individual roof segments, without prior training?
    What improvements can be achieved by implementing a one-shot learning approach using input prompts for the segmentation of building roof details, or which method is best?

    How well does #abr("SAM") generalise to different roof materials and structures?
    Can we develop strategies to improve the adaptability of #abr("SAM") to different building types and reduce the need for fine tuning?

    How can #abr("nDSM") data be effectively incorporated into the #abr("SAM") segmentation process to improve the accuracy of building analysis tasks?
    Can we develop a fusion mechanism that combines features from RGB and #abr("nDSM") data to improve the segmentation of building components?

    Design and implement an automated training data generation workflow.
    Conduct real-time segmentation experiments on aerial imagery and document the practical challenges and solutions.
    */
  ]
}