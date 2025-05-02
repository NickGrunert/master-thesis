#import "@preview/subpar:0.2.0"

#let sam() = {
  text(lang:"en")[
    = Segment Anything Model (SAM)

    == Input Prompting

    #heading(depth: 5, numbering: none, bookmarked: false)[Random Strategy]
    #heading(depth: 5, numbering: none, bookmarked: false)[Center Strategy]
    #heading(depth: 5, numbering: none, bookmarked: false)[Combined Strategy]

    == Images

    #heading(depth: 5, numbering: none, bookmarked: false)[RGB Image]
    #heading(depth: 5, numbering: none, bookmarked: false)[nDSM Image]
    #heading(depth: 5, numbering: none, bookmarked: false)[Custom Derivative Image]
    #heading(depth: 5, numbering: none, bookmarked: false)[Color Channel Swaps]

    == Results

    #heading(depth: 5, numbering: none, bookmarked: false)[Automatic Mask Generator]
    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../data/6/1/sam/0.png"), caption: [
        RGB Image.
      ]), <fig:sam:automatic:a>,
      figure(image("../data/6/1/sam/1.png"), caption: [
        Derivative Image.
      ]), <fig:sam:automatic:b>,
      figure(image("../data/6/1/sam/2.png"), caption: [
        Red Channel Swapped.
      ]), <fig:sam:automatic:c>,
      figure(image("../data/6/1/sam/3.png"), caption: [
        Green Channel Swapped.
      ]), <fig:sam:automatic:d>,
      figure(image("../data/6/1/sam/4.png"), caption: [
        Blue Channel Swapped.
      ]), <fig:sam:automatic:e>,
      caption: [
        Result Segmentations using the Automatic Mask Generator.
      ],
      label: <fig:sam:automatic>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Input Prompting]
    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../data/6/1/sam/strategy_example.png")),
      caption: [
        Example for Input Prompts depending on Strategy.
      ],
      label: <fig:sam:strategy_example>,
    )

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../data/6/1/image.png", width: 100%)),
      figure(image("../data/6/1/truth.png", width: 100%)),
      figure(image("../data/6/1/mask.png", width: 100%)),
      figure(image("../data/6/1/sam/best/mask.png", width: 100%)),

      figure(image("../data/6/18/image.png", width: 100%)),
      figure(image("../data/6/18/truth.png", width: 100%)),
      figure(image("../data/6/18/mask.png", width: 100%)),
      figure(image("../data/6/18/sam/best/mask.png", width: 100%)),

      figure(image("../data/6/19/image.png", width: 100%)),
      figure(image("../data/6/19/truth.png", width: 100%)),
      figure(image("../data/6/19/mask.png", width: 100%)),
      figure(image("../data/6/19/sam/best/mask.png", width: 100%)),
      caption: [
        Example for Input Prompts depending on Strategy.
      ],
      label: <fig:sam:mask_all>,
    )
  ]
}