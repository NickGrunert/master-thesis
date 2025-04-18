#import "@preview/subpar:0.2.0"

#let truth_compare() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Objective Analysis of Score by Comparison with Truth Data

    == Creating Ground Truth images
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






    == Metrics

    This section was originally structured in a way such that all theoretical explanations were to be done beforehand, before the results are combined and explained together.
    However, this approach was deemed not practical, as in reality each approach was thought of and tested, before analyzing the results.
    Each approach was created by taking the learnings from the previous approach into account and trying to improve upon it.
    Especially the final approach is a clear derivation developed from the previous approaches' results.
    Therefore, the following sections about by which metric the algorithm came to be evaluated each of the metrics will be eplained, example results will be shown and the lessons learned will directly be discussed.

    The example images used in the following sections are all taken from the same three example houses, meaning that the result of @fig:truth_compare:metrics:a is the same as the result of @fig:truth_compare:pearson:a and @fig:truth_compare:correlation:a, just taking different metrics into account build on @fig:truth_compare:examples:a.
    At the end of the section, the different metrics will be compared to each other and the combined results will be discussed.

    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/A.png"), caption: [
        Example A.
      ]), <fig:truth_compare:examples:a>,
      figure(image("../figures/truth_compare/metrics/B.png"), caption: [
        Example B.
      ]), <fig:truth_compare:examples:b>,
      figure(image("../figures/truth_compare/metrics/C.png"), caption: [
        Example C.
      ]), <fig:truth_compare:examples:c>,
      caption: [
        Three examples houses for the metrics to be applied to.
      ],
      label: <fig:truth_compare:examples>,
    )



    === MAE, MSE, RMSE and R2 Score <section:metrics>

    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "MAE" = (1/n) * sum_(i=1)^n |y_i - accent(y, hat)_i| $ <formula:mae>
    $ "MSE" = (1/n) * sum_(i=1)^n (y_i - accent(y, hat)_i)^2 $ <formula:mse>
    $ "RMSE" = sqrt("MSE") $ <formula:rmse>
    $ R^2 = 1 - (sum_(i=1)^n (y_i - accent(y, hat)_i)^2)/(sum_(i=1)^n (y_i - accent(y, macron))^2) $ <formula:r2>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    One approach was to use common statistical metrics for measuring the difference between two datasets.
    Namely these are the Mean Squared Error (MSE), the Mean Absolute Error (MAE), the Root Mean Squared Error (RMSE) and the R2 Score.

    The MSE, MAE and RMSE are all error metrics, which directly measure differences between the two datasets' values in regards to the assumption that the two datasets are directly corralate 1-to-1.
    The R2 Score on the other hand is a measure of how well the data fits into a linear model, also named the coefficient of determination.
    This ranges from $(-infinity, 1]$, with 1 being a perfect fit and negative values indicating that the data does not fit into the linear model at all.

    The MAE is calculated by taking the absolute difference between the two datasets and averaging it, see @formula:mae, the MSE is calculated by taking the squared difference between the two datasets and averaging it, see @formula:mse, and the RMSE is calculated by taking the square root of the MSE, see @formula:rmse.
    The R2 is calculated by taking the variance of the two datasets and dividing it by the variance of the first dataset, shown in @formula:r2.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The code snippet below shows the python implementation by using SciPy library functions, removing the need for manual implementation of the formulas.

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

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    The Learnings from the experiments using these metrics are as follows.

    The results from the MAE and RMSE are very similar here.
    This is due to the space constraint of the data inside the range of 0 to 1, which essentially means that using the MAE alone is sufficient for data analysis here, as the punishment for outliers the RMSE does is not particularly influential or meaningful.

    Analyzing the R2 Score is more complex due to its open range of $(-infinity, 1]$.
    Interpreting the R2 Score is difficult, as one would need to create a valid interpretation of how the score's magnitude relates to the algorithm's performance, which may not be possible.
    Overall, it can be said that the values tend to be negative, or even strongly negative, highly indicating that the algorithm does not correlate in the way this section assumes.
    However, the general idea of the R2 Score and measuring how well the data fits into the linear model is still a desired property of the algorithm, which will need to be kept in mind for the later steps.
    
    Especially @fig:truth_compare:metrics:a shows that the R2 Score is highly negative, indicating that the algorithm does not correlate with the ground truth data at all.
    However, looking at the data implicates the opposite, them clearly being in a linear relationship, just a tilted one, not stemming from the origin (0, 0).
    This is a clear indication that the algorithm does not correlate with the ground truth data in the way this section assumes and indicates a need for improvement.

    In direct comparison @fig:truth_compare:metrics:c shows a very good correlation with the ground truth data, which is also reflected in the R2 Score.
    Still, this merely means that the linear relationship the scores and truth scores are in is simply more tilted towards the origin than Example A was.

    @fig:truth_compare:metrics:b kind of paints a third picture.
    The R2 Score is still negative, not as low as Example A, but a little more than Example C.
    Looking at it visually shows that the data is way more widespread than in the other two examples.
    This also shows the problem of a score of 0.8 in the scoring system being able to range from exemplary 0.5 to 0.9 inside the truth scores.
    This is a clear violation of the requirement that the scores should be reliable, meaning an accurate representation of the algorithm's performance and thereby truth scores.
    Since the metrics however in no way represent this mismatch, this is another point that should be addressed in the next iterations of the algorithm.

    In short, these metrics currently directly measure a 1-to-1 relationship between the scores and the truth scores.
    This however, is not neccessaryly the desired property of the algorithm, as this is an assumption too constrained, not neccessaryly representing reality.
    There will need to be a way to measure the correlation between the two datasets, without assuming a strict 1-to-1 relationship.
    Also right now, the algorithm does not represent singular value variability, which is a clear violation of the requirement of the algorithm.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/metrics1.png"), caption: [
        Example A.
      ]), <fig:truth_compare:metrics:a>,
      figure(image("../figures/truth_compare/metrics/metrics2.png"), caption: [
        Example B.
      ]), <fig:truth_compare:metrics:b>,
      figure(image("../figures/truth_compare/metrics/metrics3.png"), caption: [
        Example C.
      ]), <fig:truth_compare:metrics:c>,
      caption: [
        Three examples of using the MAE, MSE, RMSE and R2 Score to compare the algorithm's scores to the ground truth data.
      ],
      label: <fig:truth_compare:metrics>,
    )



    === Pearson Coefficient

    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "cosine similiarty" = (arrow(x) dot arrow(y)) / (||arrow(x)|| dot ||arrow(y)||) $ <formula:cosine>
    $ "pearson coefficient" = (n * sum(x * y) - sum(x) * sum(y)) / sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2)) $ <formula:pearson>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    Another approach to measure the correlation between two datasets is the Cosine Similarity @Cosine2.
    Since it essentially measures the similiarity between the data point vectors, this approach was thought of to try to measure how good the scoring is in terms of direction.
    The cosine similarity is calculated by taking the dot product of the two vectors and dividing it by the product of the magnitudes of both vectors, which can be seen in @formula:cosine.

    However, this similiarity is based from the direction of the origin (0, 0).
    This still assumes a 1-to-1 relationship between the two datasets, which as discussed is not a desired property of the algorithm.
    One fix for this is normalization of the data, which would move the data into the full range of 0 to 1.
    This would solve the problem of constraint.

    This way of calculating cosine similiarity normalized is essentially the same as the Pearson Coefficient @Pearson2 @Pearson3 @Pearson4.
    The Pearson Coefficient can measure any linear correlation between two datasets.
    It measures between -1 and 1 on how much the two datasets correlate with each other, with 1 being a perfect correlation and -1 being a perfect anti-correlation.
    The Pearson Coefficient is calculated by taking the covariance of the two datasets and dividing it by the product of the standard deviation of both datasets, which can be seen in @formula:pearson.
    A pearson coefficient of 1 during experimentation would mean that the two datasets are perfectly correlated.
    In that case the score calculated from the segmentation algorithm and the ground truth data are indeed comparable due to good correlation.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    However, since scipy offers the pearsonr function, we do not need to implement this ourselves @Pearson1.
    The function takes two arrays as input and returns the Pearson coefficient and the p-value, whereas the latter will not be used here.
    A short abstract of code can be seen in the following example code snippet.

    ```python
    from scipy.stats import pearsonr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = pearsonr(scores, truth_scores)
    print(f"Pearson: {r:.3f}")  # Output: Pearson r: 1.000 (perfect linear correlation)
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    @fig:truth_compare:pearson shows three different calculations of the Pearson Coefficient on the example images.
    Some of the individual results clearly show a very good correlation close to 1, which would be the ideal case for the algorithm.
    As expected, @fig:truth_compare:pearson:b is an outlier to this.
    It shows either values close to 0 indicating no correlation at all or using the Sobel derivative method even a negative value, which would mean that our scoring algorithm anti-correlates with the ground truth data here.
    Taken at face value this would be devastating for the algorithm.
    There will definitely need to be an evaluation on the result data of Example B to find out, if the algorithm actually failed here and if this is actually an indicator on the algorithm's performance and if it indeed fails to satisfy the requirements.

    @fig:truth_compare:pearson:a and @fig:truth_compare:pearson:c show a very good correlation with the ground truth data, which is indeed reflected in the Pearson Coefficient.
    The difference between why exactly some values are at 0.6 and some are 0.8 is not directly clear, however, both values are good enough indicators for good score correlation.

    In direct comparison to @section:metrics, the Pearson Coefficient is a clear improvement over the previous metrics.
    Loosing the assumption of a strict 1-to-1 relationship between the two datasets is a clear improvement, since being more flexible in accepting the correlation is good, especially since as can be seen in the data, the algorithm's score is way more strict than the ground truth data score.
    This is most likely due to facts like the scoring system harshly punishing multi plateau segmentations by zeroing them out, while the ground truth data's IOU values are only minorly effected by such errors.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/pearson1.png"), caption: [
        Example A.
      ]), <fig:truth_compare:pearson:a>,
      figure(image("../figures/truth_compare/metrics/pearson2.png"), caption: [
        Example B.
      ]), <fig:truth_compare:pearson:b>,
      figure(image("../figures/truth_compare/metrics/pearson3.png"), caption: [
        Example C.
      ]), <fig:truth_compare:pearson:c>,
      caption: [
        The three examples of the Pearson Coefficient applied to the segmentations from the algorithm compared to the ground truth data.
      ],
      label: <fig:truth_compare:pearson>,
    )



    === Combination of Metrics by using a Linear Regressor

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    Taking into account especially the learning from the last section, the next step was to combine the different metrics into one single metric.
    For this, the requirement is essentially just calculating any kind of linear relationship and using metrical comparison towards that relationship.

    This was achieved by using a simple Linear Regressor @LinearRegressor, which fits and calculates the linear regression line between the two datasets.
    Using SciPy's LinearRegression function, we can easily fit the data and calculate the R2 Score and the Mean Absolute Error (MAE) of the linear regression line.
    This fulfils the requirement of a non strict 1-to-1 linear relationship between the two datasets, as well as returns the metrics which indicate the performance of the algorithm.

    To calculate the correlation score, a simple weighted average of the R2 Score and the MAE is used.
    However, MAE by itself is an error metric.
    To create a resulting score, after normaliting the MAE to the range of 0 to 1, the MAE is subtracted from 1.
    This is done to move the MAE into the same range as the R2 Score, and fullfill the requiremt of the optimal resulting score being 1.
    The resulting correlation score itself is then calculated by taking the weighted average of the R2 Score and the MAE, which can be seen in the code example below.
    For simplicity the alpha value is set to 0.5, meaning that both metrics are weighted equally.
    While it probably would make sense to weight the R2 Score higher, as it is a measure of how well the data fits a linear model.
    This was however not done due to the fact that an objective analysis on the actual use of this weighing would be too difficult to achieve here.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
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

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    Shown in @fig:truth_compare:correlation are the results of the new metric applied to exempt example images.
    The results are very promising, as they far better than the previous approaches correlate to expected scores.
    None of the results, show particularly high absolute errors towards their respective linear fit.
    However, the R2 scores could be improved, as in some of the cases the values are not particularly high, indicating that the linear regression line does not fit the data particularly well.

    Using the Sobel derivative in @fig:truth_compare:correlation:c shows one such example, where the R2 score is very low.
    In a way however, this is the expected result, as looking at the calculated scores does indeed reveal that the algorithm utterly fails to produce good results in this case, which is represented by this low comparison score.
    Using the Scharr Operator in @fig:truth_compare:correlation:b also shows this failure to produce results be represented by its R2 score.
    However, since this iteration of results shows no negative values for the R2 score, this is a clear improvement over the previous iterations of the algorithm.
    This namely means, that we are no longer assuming a wrong relationship between the data, like it was done in the previous iteration where we essentially always compared to a diagonal from (0, 0) to (1, 1).

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/truth_compare/metrics/correlation1.png"), caption: [
        Example A.
      ]), <fig:truth_compare:correlation:a>,
      figure(image("../figures/truth_compare/metrics/correlation2.png"), caption: [
        Example B.
      ]), <fig:truth_compare:correlation:b>,
      figure(image("../figures/truth_compare/metrics/correlation3.png"), caption: [
        Example C.
      ]), <fig:truth_compare:correlation:c>,
      caption: [
        Correlation Scores for the three examples using the linear regressor and plotting the generated line in red.
      ],
      label: <fig:truth_compare:correlation>,
    )
  ]

  pagebreak()
}