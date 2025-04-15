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

    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    ==== Pearson

    The Pearson Coefficient can measure the linear correlation between two datasets.
    It measures between -1 and 1 on how much the two datasets correlate with each other, with 1 being a perfect correlation and -1 being a perfect anti-correlation.
    The Pearson Coefficient is calculated by taking the covariance of the two datasets and dividing it by the product of the standard deviation of both datasets, which can be seen in @formula:pearson.
    A pearson coefficient of 1 during experimentation would mean that the two datasets are perfectly correlated, meaning that the score calculated from the segmentation algorithm and the ground truth data are indeed comparable. @Pearson2 @Pearson3 @Pearson4

    $ r = (n * sum(x * y) - sum(x) * sum(y)) / sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2)) $ <formula:pearson>

    However, since scipy offers the pearsonr function, we do not need to implement this ourselves @Pearson1.
    The function takes two arrays as input and returns the Pearson coefficient and the p-value, whereas the latter will not be used here.
    A short abstract of code can be seen in the following pseudo-code snippet.

    ```python
    import numpy as np
    from scipy.stats import pearsonr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = pearsonr(scores, truth_scores)
    print(f"Pearson r: {r:.3f}")  # Output: Pearson r: 1.000 (perfect linear correlation)
    ```

    ==== Cosine Similiarity

    ==== Using common other metrics

    ==== Combination of Metrics by using a Linear Regressor

    ```python
    model = LinearRegression()
    model.fit(np.array(scores).reshape(-1, 1), np.array(truth_scores).reshape(-1, 1))
    r2 = model.score(np.array(scores).reshape(-1, 1), np.array(truth_scores).reshape(-1, 1))
    trend_pred = model.predict(np.array(scores).reshape(-1, 1))
    mae = mean_absolute_error(np.array(truth_scores).reshape(-1, 1), trend_pred)
    mae_norm = mae / (max(truth_scores) - min(truth_scores) + 1e-10)

    alpha = 0.5
    correlation_score = (alpha * r2) + ((1 - alpha) * (1 - mae_norm))
    print(f"Correlation Score: {correlation_score:.3f}") # Output: Correlation Score: 1.000 (perfect correlation)
    ```

    === Results

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