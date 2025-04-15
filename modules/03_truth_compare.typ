#import "@preview/subpar:0.2.0"

#let truth_compare() = {
  text(lang:"en")[
    == Objective Analysis of Score by Comparison with Truth Data

    === Creating Ground Truth images
    For actual evaluation and validation of the algorithms it is necessary to at least create at least some objective data to compare the algorithm to.
    This ground truth data will be the reference point onto which the algorithm will be compared, which in turn will allow an actual quantitative evaluation of the algorithms performance.
    It will serve as proof of the algorithms accuracy and reliability.

    Therefore, 20 Segmentation where created by me, which will serve as the basis for the evaluation in this step.
    @GroundTruth1 do talk about the problems which arise from the process of data creation.
    As already talked about the pictures which are currently worked with are not of high pixel quality, which means that especially on the edges between segments the line is very blurry as to where the actual edge is.
    Also some edges are very hard to see with the human eye or even nearly invisible on the nDSM data as well as the RGB data, but they only become truly visible when using the derivative and colouring the picture by that data.
    This adds another layer of challenge to the creation of the ground truth data.
    One other point is once again that the RGB data and the nDSM data are not perfectly aligned, which means that trying to create a ground truth from only the RGB data would create a different result as to the nDSM data, especially on the house outlines, where the missalignment becomes very visible.

    However these challenges, a sufficiently accurate ground truth is assumed to be sufficient in creating a general idea whether the algorithm is performing in a satisfactory manner or not.
    Therefore in the following sections we will take a look at the different metrics which are used to evaluate the algorithm.

    === Metrics

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/pearson.png"), caption: [
        Surface Growth.
      ]), <fig:truth_compare:metrics:a>,
      figure(image("../figures/truth_compare/metrics/cosine.png"), caption: [
        Separation.
      ]), <fig:truth_compare:metrics:b>,
      figure(image("../figures/truth_compare/metrics/error_metrices.png"), caption: [
        Re-linking.
      ]), <fig:truth_compare:metrics:c>,
      figure(image("../figures/truth_compare/metrics/new_score.png"), caption: [
        Magnitude.
      ]), <fig:truth_compare:metrics:d>,
      caption: [
        The four iterations of metrics which try to evaluate the scoring system to ground truth data
      ],
      label: <fig:truth_compare:metrics>,
    )
  ]

  pagebreak()
}