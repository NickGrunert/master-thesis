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

    Originally i had intended to write this sections structured in a way such that all theoretical explanations come first, before the results are combined and explained together.
    However, this approach was deemed not practical, as in reality each approach was thought of and tested, before analyzing the results and on their basis thinking of the next one.
    Especially the final approach is a clear derivation developed from the previous approaches' results.
    Therefore, the following sections about by which metric the algorithm came to be evaluated each of the metrics will be eplained, example results will be shown and the lessons learned will directly be discussed.

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
    from scipy.stats import pearsonr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = pearsonr(scores, truth_scores)
    print(f"Pearson r: {r:.3f}")  # Output: Pearson r: 1.000 (perfect linear correlation)
    ```

    @fig:truth_compare:pearson shows three different calculations of the Pearson Coefficient on different example images.
    Some of the individual results clearly show a very good correlation close to 1, which would be the ideal case for the algorithm.
    However, some of the values, especially in @fig:truth_compare:pearson:c are outliers to this.
    They show either no correlation with values close to 0 or even negative values, which in theory would mean that our scoring algorithm anti-correlates with the ground truth data.
    Taken at face value this would be devastating for the algorithm, as it would mean that the algorithm is not able to produce a segmentation which is comparable to the ground truth data.cos(x, y)

    However, looking at the data with the human eye and analyzing the data myself shows that the Pearson Coefficient has a clear flaw when applied like this.
    The comparison algorithm currently merely analyzes he data in itself, but completely ignores the wider scale, namely the fact that this data is constrained inside the space between 0 and 1 in x and y direction (which represents the score and the ground truth data).
    Therefore the next experiments will also show the datapoints not being constrained in their range, but rather in the complete space of 0 to 1.
    This should facilitate better visual confirmation of the algorithm's performance, since the data is put more into perspective of the overall possible data values.

    While it is acknowledgable that especially the negative values in the figure are concerning, first different approaches were sought of, which could take this into account and paint a better picture about the algorithms performance.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/pearson.png"), caption: [
        Surface Growth.
      ]), <fig:truth_compare:pearson:a>,
      figure(image("../figures/truth_compare/metrics/pearson2.png"), caption: [
        Separation.
      ]), <fig:truth_compare:pearson:b>,
      figure(image("../figures/truth_compare/metrics/pearson3.png"), caption: [
        Re-linking.
      ]), <fig:truth_compare:pearson:c>,
      caption: [
        Three different examples of the Pearson Coefficient applied to the segmentations from the algorithm compared to the ground truth data.
      ],
      label: <fig:truth_compare:pearson>,
    )



    ==== Cosine Similiarity TODO

    Another approach to measure the correlation between two datasets is the Cosine Similarity @Cosine2.
    Since it essentially measures the similiarity between the data point vectors, this approach was thought of to try to measure how good the scoring is in terms of direction.
    The cosine similarity is calculated by taking the dot product of the two vectors and dividing it by the product of the magnitudes of both vectors, which can be seen in @formula:cosine.

    $ "cosine similiarty" = (arrow(x) dot arrow(y)) / (||arrow(x)|| dot ||arrow(y)||) $ <formula:cosine>

    While once again we could calculate this ourselves, the scikit-learn library offers a function to calculate this @Cosine1, as shown in te short pseudo-code example below.

    ```python
    from sklearn.metrics.pairwise import cosine_similarity

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    cos_sim_sklearn = cosine_similarity(scores, truth_scores)[0,0]
    print(f"Cosine Similarity (scikit-learn): {cos_sim_sklearn:.4f}")
    ```



    ==== Using common other metrics

    The next approach was to use more common statistical metrics for measuring the difference between two datasets.
    Namely these are the Mean Squared Error (MSE), the Mean Absolute Error (MAE), the Root Mean Squared Error (RMSE) and the R2 Score.

    Between the first metrices the MSE, MAE and RMSE are all error metrics, which directly measure differences between the two datasets' values.
    The MAE is calculated by taking the absolute difference between the two datasets and averaging it, the MSE is calculated by taking the squared difference between the two datasets and averaging it, and the RMSE is calculated by taking the square root of the MSE.

    The R2 Score however, is a measure of how well the data fits into a linear model, named the coefficient of determination.
    This is calculated by taking the variance of the two datasets and dividing it by the variance of the first dataset, shown in @formula:r2.

    $ R^2 = 1 - (sum_(i=1)^n (y_i - accent(y, hat)_i)^2)/(sum_(i=1)^n (y_i - accent(y, macron))^2) $ <formula:r2>

    Once again, the below pseudo-code shows their simple implementation by using library functions.

    ```python
    from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    mae = mean_absolute_error(scores, truth_scores)
    mse = mean_squared_error(scores, truth_scores)
    rmse = (mse)**(1/2)
    r2 = r2_score(scores, truth_scores)

    print("MAE:", mae)
    print("MSE:", mse)
    print("RMSE:", rmse)
    print("R2:", r2)
    ```

    The Learnings from the experiments are as follow:
    - The MAE and RMSE are very similar. 
      This is due to the space constraint of the data inside the range of 0 to 1 and essentially means that using the MAE alone is sufficient for data analysis.
    - Analyzing the R2 Score is difficult due to its range of $(-infinity, 1]$.
      Interpreting the R2 Score is difficult here, as one would need to create a valid interpretation of how the score's magnitude relates to the algorithm's performance, which may not be possible.
      However, the general idea of the R2 Score is that it measures how well the data fits a linear regression model, which is still a desired property of the algorithm, which will need to be kept in mind for the next steps.
    - These metrics currently directly measure a 1-to-1 relationship between the scores and the truth scores.
      This however, is not neccessaryly the desired property of the algorithm, as this is a too contstrained assumption.
      It is enough to merely assume a linear relationship between the datasets without having to assume this line could not be shifted or tilted.
      The only actual requirement that exists is reliability of the algorithm, meaning a better score should actually perform better than a worse score.

    ==== Combination of Metrics by using a Linear Regressor

    Taking into account especially the learning from the last section, the next step was to combine the different metrics into one single metric.
    For this, the following was deemed neccessary:
    - Any kind of linear relationship and metrical comparison to that relationship.

    This was achieved by using a simple Linear Regressor @LinearRegressor, which fits and calculates the linear regression line between the two datasets.
    Using SciPy's LinearRegression function, we can easily fit the data and calculate the R2 Score and the Mean Absolute Error (MAE) of the linear regression line.
    This fulfils the requirement of a non strict 1-to-1 linear relationship between the two datasets, as well as returns the metrics which indicate the performance of the algorithm.

    To calculate the correlation score, a simple weighted average of the R2 Score and the MAE is used.
    For this, the MAE is normalized as well as inverted, as the MAE is an error matric and therefore should be minimized, while we are looking for a score, which should be maximized.
    Once again, the pseudo-code below shows the implementation of this approach.

    ```python
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import mean_absolute_error

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    scores = np.array(scores).reshape(-1, 1)
    truth_scores = np.array(truth_scores).reshape(-1, 1)

    model = LinearRegression()
    model.fit(scores, truth_scores)
    r2 = model.score(scores, truth_scores)
    trend_pred = model.predict(scores)
    mae = mean_absolute_error(truth_scores, trend_pred)
    mae_norm = mae / (max(truth_scores) - min(truth_scores) + 1e-10)

    alpha = 0.5
    correlation_score = (alpha * r2) + ((1 - alpha) * (1 - mae_norm))
    print(f"Correlation Score: {correlation_score:.3f}") # Output: Correlation Score: 1.000 (perfect correlation)
    ```

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/new_score.png"), caption: [
        Surface Growth.
      ]), <fig:truth_compare:new_score:a>,
      figure(image("../figures/truth_compare/metrics/new_score2.png"), caption: [
        Separation.
      ]), <fig:truth_compare:new_score:b>,
      figure(image("../figures/truth_compare/metrics/new_score3.png"), caption: [
        Re-linking.
      ]), <fig:truth_compare:new_score:c>,
      caption: [
        Example results of using linear regression to calculate the correlation score.
      ],
      label: <fig:truth_compare:new_score>,
    )

    Shown in @fig:truth_compare:new_score are the results of the new metric applied to exempt example images.
    The results are very promising, as they far better than the previous approaches correlate to expected scores.
    None of the results, show particularly high absolute errors towards their respective linear fit.
    However, the R2 scores could be improved, as in some of the cases the values are not particularly high, indicating that the linear regression line does not fit the data particularly well.

    Using the Sobel derivative in @fig:truth_compare:new_score:c shows one such example, where the R2 score is very low.
    In a way however, this is the expected result, as looking at the calculated scores does indeed reveal that the algorithm utterly fails to produce good results in this case, which is represented by this low comparison score.
    Using the Scharr Operator in @fig:truth_compare:new_score:b also shows this failure to produce results be represented by its R2 score.
    However, since this iteration of results shows no negative values for the R2 score, this is a clear improvement over the previous iterations of the algorithm.
    This namely means, that we are no longer assuming a wrong relationship between the data, like it was done in the previous iteration where we essentially always compared to a diagonal from (0, 0) to (1, 1).

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