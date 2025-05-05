#import "@preview/subpar:0.2.0"

#let sam() = {
  text(lang:"en")[
    = Segment Anything Model (SAM)




    == Images



    #heading(depth: 5, numbering: none, bookmarked: false)[RGB Image]

    #heading(depth: 5, numbering: none, bookmarked: false)[nDSM Image]
    #subpar.grid(
      columns: 5,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/sam_mask.png")), clip: true, width: 100%, inset: (right: -2.9in)),
      caption: [
        nDSM Image.
      ],
      label: <fig:sam:images:ndsm>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Custom Derivative Image]
    ```python
    def get_color(x, y):
      magnitude = np.sqrt(x**2 + y**2)

      if x >= 0 and y >= 0:
          # Red for Quadrant I
          return (magnitude, 0, 0)
      elif x < 0 and y >= 0:
          # Green for Quadrant II
          return (0, magnitude, 0)
      elif x < 0 and y < 0:
          # Blue for Quadrant III
          return (0, 0, magnitude)
      else:
          # Yellow for Quadrant IV
          return (magnitude, magnitude, 0) # Yellow = Red + Green
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Color Channel Swaps]

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 5,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/0.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/1.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/2.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/3.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/4.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      caption: [
        Image Types which will be used in further Analysis.
      ],
      label: <fig:sam:images>,
    )
      




    == Input Prompting



    #heading(depth: 5, numbering: none, bookmarked: false)[Random Strategy]

    #heading(depth: 5, numbering: none, bookmarked: false)[Center Strategy]

    #heading(depth: 5, numbering: none, bookmarked: false)[Combined Strategy]
    
    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../data/6/1/sam/strategy_example.png")),
      caption: [
        Input Prompts depending on Strategy and Parameter.
      ],
      label: <fig:sam:strategy_example>,
    )




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
        Using SAM with Input Prompts from the Mask.
      ],
      label: <fig:sam:mask_all>,
    )
  ]
}