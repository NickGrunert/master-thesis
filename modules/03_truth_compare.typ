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
    The evaluation and validation of algorithms necessitate the creation of objective data for the purpose of comparison.
    The ground truth data will function as the reference point against which the algorithm will be evaluated. 
    This quantitative evaluation will allow for an assessment of the algorithm's performance, thereby substantiating its accuracy and reliability.

    Consequently, 20 segmentation were created, which will serve as the basis for the evaluation in this step.
    These metrics are derived from images which correspond to the 60th percentile of the entire image dataset.
    This was selected as they adequately represent the data overall, being sufficiently small to be processed in a reasonable timeframe while still exhibiting sufficient complexity.
    Additionally, this section of the data encompasses an acceptable range of roof shapes, from simple to complex, including mainly normal but also a flat roof with a design not too simple.

    @GroundTruth1 elaborates on the issues that emerge during the process of data generation.
    As previously discussed, the images currently under consideration are characterized by suboptimal pixel quality. 
    This deficiency manifests particularly in thin roof regions, where the delineation of the edge is rendered indistinct.
    Additionally, certain edges are challenging to discern with the naked eye, and they are often imperceptible in both the nDSM and RGB data.
    Especially in the RGB data regions with large shadows, the edges are not clearly visible.
    However, these edges become clearly visible when utilizing the derivative and coloring the image with this data.
    This introduces an additional layer of complexity and duration to the process of generating ground truth data.

    It must again be noted that the RGB data and the nDSM data are not perfectly aligned. 
    Consequently, an attempt to create a ground truth based only on the RGB data would yield a different result than the nDSM data, particularly with regard to the house outlines, where the misalignment becomes quite evident.

    Nonetheless, it is proposed that a sufficiently accurate ground truth is sufficient to create a general idea of whether the algorithm is performing in a satisfactory manner.
    Provided that the general structure and number of segments are accurate, the ground truth can be considered sufficiently reliable. 
    This is because minor discrepancies in the output score calculated on the ground truth do not invalidate the algorithm.









    == Metrics

    The original structure of this section was designed to prioritize the presentation of theoretical explanations prior to the combination and explanation of the results.
    However, this approach was deemed impractical, as each approach was thoroughly considered and evaluated before conducting a comprehensive analysis of the results.
    Each subsequent approach was developed by incorporating the insights from the preceding approach and making attempts to enhance it based on the outcomes of the earlier approaches.
    Therefore, the ensuing sections are devoted to the following: an exposition of the metrics by which the algorithm was evaluated; the presentation of example results; and a direct discussion of the lessons learned.

    The example images employed in the ensuing sections are all drawn from the same three example houses. 
    This ensures that the outcome of @fig:truth_compare:metrics:a is equivalent to that of @fig:truth_compare:pearson:a and @fig:truth_compare:correlation:a, with the sole difference being the consideration of disparate metrics. 
    These metrics are further elaborated upon in @fig:truth_compare:examples:a.
    In the final section, a comparative analysis of the various metrics will be conducted, followed by a discussion of the aggregate results.

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
    One approach entailed the utilization of conventional statistical metrics for the assessment of the discrepancy between two datasets.
    Specifically, the following metrics are of relevance: the mean squared error (MSE), the mean absolute error (MAE), the root mean squared error (RMSE), and the R2 score.

    The mean absolute error (MAE), the mean squared error (MSE), and the root mean squared error (RMSE) are all error metrics. These metrics directly measure the differences between the values of two datasets, under the assumption that the two datasets are directly correlated 1-to-1.
    The R2 score is a measure of the extent to which the data aligns with a linear model, also referred to as the coefficient of determination.
    This range extends from $(-infinity, 1]$, with 1 representing a perfect fit and negative values denoting a lack of fit for the data within the linear model.

    The mean absolute error (MAE) is calculated by taking the absolute difference between the two datasets and averaging it (see @formula:mae). The mean squared error (MSE) is calculated by taking the squared difference between the two datasets and averaging it (see @formula:mse). The root mean squared error (RMSE) is calculated by taking the square root of the MSE (see @formula:rmse).
    The R2 is calculated by taking the variance of the two datasets and dividing it by the variance of the first dataset, as demonstrated in @formula:r2.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The code segment that follows illustrates the Python implementation by leveraging SciPy library functions, thereby eliminating the necessity for manual formula implementation.

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
    The following conclusions were derived from the experiments employing these metrics.

    The results from the MAE and RMSE are highly congruent in this instance.
    This phenomenon can be attributed to the inherent limitations of the data, which is constrained within the range of 0 to 1. Consequently, the utilization of the mean absolute error (MAE) as a standalone metric is sufficient for data analysis in this context, as the impact of the root mean square error (RMSE) on outliers is deemed negligible.

    The R2 score's open range of $(-infinity, 1]$ complicates analysis.
    Interpreting the R2 Score poses a significant challenge, as it necessitates the creation of a valid interpretation of the relationship between the score's magnitude and the performance of the algorithm, a task that may not be feasible.
    An evaluation indicates that the values predominantly manifest a negative tendency, with most instances exhibiting lower magnitudes. 
    However, it is noteworthy that some instances display significantly higher magnitudes.
    This observation strongly suggests that the algorithmic correlation does not align much with the suppositions made in this particular section.
    However, the fundamental principle of the R2 Score and the assessment of the congruence between the data and a linear model remains an essential property of the algorithm, a consideration that will be pertinent to the subsequent steps.
    
    The R2 Score demonstrated by @fig:truth_compare:metrics:a is notably negative, suggesting a complete absence of correlation between the algorithm and the ground truth data.
    However, an examination of the data suggests an alternative conclusion, indicating a linear relationship that is simply tilted, rather than originating from the origin (0, 0), as the R2 Score implemented here assumes.

    In direct comparison, the @fig:truth_compare:metrics:c metric reveals a strong correlation with the ground truth data, as evidenced by it's calculated R2 score.
    However, this observation merely indicates that the linear relationship between the scores and truth scores is more skewed towards the origin in comparison to the scenario depicted before.

    @fig:truth_compare:metrics:b offers yet another perspective.
    The R2 Score remains in a negative range, although it is less pronounced than in in the first example but more significant than in the second.
    Visual examination of the data reveals a more widespread distribution compared to the other two examples.
    This demonstrates the challenge posed by a score of 0.8 in the scoring system being able to range from exemplary 0.5 to 0.9 within the truth scores.
    This constitutes a clear violation of the requirement that the scores be reliable, meaning an accurate representation of the algorithm's performance and thereby truth scores.
    However, given that the metrics are not capable of representing this discrepancy, it is imperative that this issue be addressed in subsequent iterations of the algorithm.

    In summary, the metrics in question directly measure a non tilted linear one-to-one relationship between the scores and the truth scores.
    However, this is not necessarily desired.
    This is due to the fact that the assumption is too constrained.
    It is imperative to establish a methodology for measuring the correlation between the two datasets without presuming a rigid 1-to-1 relationship.
    Furthermore, the prevailing algorithmic framework is found to be deficient in its inability to accommodate variability in singular values. 
    This shortcoming constitutes a flagrant infringement upon the algorithm's fundamental criteria, necessitating its rectification subsequent to the implementation of a more accurate validation technique.

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



    === Pearson Coefficient <section:pearson>

    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "cosine similiarty" = (arrow(x) dot arrow(y)) / (||arrow(x)|| dot ||arrow(y)||) $ <formula:cosine>
    $ "pearson coefficient" = (n * sum(x * y) - sum(x) * sum(y)) / sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2)) $ <formula:pearson>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    An alternative approach to measuring the correlation between two datasets is the Cosine Similarity @Cosine2.
    This approach was conceived as a means to assess the quality of the scoring in terms of direction, given its fundamental purpose being to quantify the similarity between the data point vectors.
    The cosine similarity is calculated by taking the dot product of the two vectors and dividing it by the product of the magnitudes of both vectors. This calculation can be expressed as follows:@formula:cosine.

    Nevertheless, said similarity is still derived from the direction of the origin (0, 0).
    This means the algorithm still asummes a one-to-one relationship between the two datasets, a property that, as previously discussed, is not wanted.
    A potential solution to this issue is the normalization of the data, which would result in the data falling within the full range of 0 to 1.
    This would solve said problem.

    The calculation of cosine similarity normalized is analogous to the calculation of the Pearson coefficient @Pearson4 @Pearson2 @Pearson3.
    The Pearson coefficient is a measure of linear correlation between two datasets.
    The correlation coefficient ranges from -1 to 1, with 1 representing a perfect positive correlation and -1 representing a perfect negative correlation.
    The Pearson coefficient is calculated by taking the covariance of two datasets and dividing it by the product of the standard deviations of said datasets. This calculation can be performed using the @formula:pearson function.
    A Pearson coefficient of 1 during experimentation would indicate a perfect correlation between the two datasets.
    In such circumstances, the score derived from the segmentation algorithm and the ground truth data are demonstrably congruent, attributable to a reliable correlation.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    Nevertheless, given that Scipy provides the Pearson function @Pearson1, it is unnecessary to implement this function independently.
    The function accepts two arrays as inputs and produces the Pearson coefficient.
    Note that the method also returns a p-value demonstrating confidence, which however will not be utilized in this context.
    The following example code snippet offers a small abstract of the code.

    ```python
    from scipy.stats import pearsonr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = pearsonr(scores, truth_scores)
    print(f"Pearson: {r:.3f}")  # Output: Pearson r: 1.000 (perfect linear correlation)
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    @fig:truth_compare:pearson presents three distinct calculations of the Pearson coefficient on the example images.
    The findings demonstrate a notable degree of concordance, with several outcomes exhibiting a strong positive correlation approaching 1, a value that would be optimal for the algorithm.

    As anticipated, @fig:truth_compare:pearson:b is still an outlier in this context.
    The results indicate a lack of correlation, as evidenced by values approaching 0. Alternatively, the Sobel derivative method reveals negative values, suggesting an anti-correlation between the scoring algorithm and the ground truth data.
    If accepted without further investigation, this would have a seriously detrimental effect on the algorithm.
    A thorough evaluation of the result data from Example B is imperative to ascertain whether the algorithm has indeed faltered. 
    This evaluation will serve to determine if the algorithm's performance is an indication of its effectiveness and if it is capable of meeting the specified requirements.

    As demonstrated in @fig:truth_compare:pearson:a and @fig:truth_compare:pearson:c, they exhibit a highly favorable correlation with the ground truth data, a finding that is reflected in the Pearson coefficient.
    A direct comparison of the Pearson Coefficient with @section:metrics reveals its superiority over the previous metrics.
    The relaxation of the assumption of a rigid 1-to-1 relationship between the two datasets signifies a substantial enhancement, as it allows for greater flexibility in accepting the correlation. 

    The discrepancy in the values, with some at 0.6 and others at 0.8, remains to be elucidated. 
    However, it is evident that both values serve as at least adequate indicators for the correlation of scores.
    It is reasonable to hypothesize that this phenomenon is attributable to the scoring system's stringent penalization of undersegmentation segmentations, which scores are completely nullified.
    In contrast, the ground truth data's IOU values exhibit only a marginal sensitivity to such inaccuracies.

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
    The subsequent stage of the research involved the formulation of a linear function, with the objective of calculating the correlation between the two datasets directly.
    The prerequisite for this endeavor entails the calculation of the most optimal linear relationship and the implementation of metrical comparison of the data in alignment with that relationship.

    This objective was accomplished by implementing a linear regressor @LinearRegressor, which facilitated the calculation of a linear regression line between the two datasets.
    Employing the LinearRegression function of SciPy facilitates the fitting of the data and the calculation of the R2 Score and the Mean Absolute Error (MAE) towards that linear regression line.
    This fulfills the requirement of a non-strict 1-to-1 linear relationship between the two datasets, as well as returns the metrics that indicate the performance of the algorithm.
    In addition, the R2 Score this time is effectively constrained to the range of 0 to 1 in this iteration, in contrast to previous iterations. 
    This is due to the fact that, under the most sub-optimal conditions, the algorithm would return 0, meaning the regressor essentially mimicing the mean of the data.
    This represents a marked enhancement over earlier iterations, in which the R2 Score was not constrained and could attain unconstrained negative values, leading to challenges in interpretation.

    As previously outlined in @section:metrics, the MAE is a reliable metric for assessing the accuracy of the algorithm, while the R2 Score is a valuable indicator of the suitability of the data for a linear model.
    The resulting correlation score is calculated by taking a simple weighted average of the R2 score and the MAE.
    Nevertheless, the MAE is inherently an error metric.
    Therefore, following the normalization of the MAE to the range of 0 to 1, it is subtracted from 1, thereby inverting the task to maximize the objective.
    This is done to align the MAE with the R2 Score, thereby ensuring that the resulting optimal score is 1.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The resulting correlation score is then calculated by taking the weighted average of the R2 score and the MAE, as illustrated in the following code example.
    It is evident that the MAE undergoes an inversion.
    However, the R2 Score's constrained range is not immediately apparent.
    Consequently, the resulting correlation score is also constrained to the range of 0 to 1, which is the desired property of the algorithm.
    To ensure simplicity, the alpha value is set to 0.5, thereby assigning equal weight to both metrics.

    ```python
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import mean_absolute_error

    def calculate_linear_regression(scores, truth_scores, alpha=0.5):
        scores_reshaped = np.array(scores).reshape(-1, 1)
        truth_scores_reshaped = np.array(truth_scores).reshape(-1, 1)

        model = LinearRegression()
        model.fit(scores_reshaped, truth_scores_reshaped)
        r2 = model.score(scores_reshaped, truth_scores_reshaped)
        trend = model.predict(scores_reshaped)
        mae = mean_absolute_error(truth_scores_reshaped, trend)
        mae_norm = mae / (max(truth_scores) - min(truth_scores) + 1e-10)
        mae_norm_score = 1 - mae_norm

        correlation_score = (alpha * r2) + ((1 - alpha) * mae_norm_score)
        return r2, trend, mae_norm_score, correlation_score

    # Example Usage:
    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r2, trend, mae_score, correlation_score = calculate_linear_regression(scores, truth_scores)

    print(f"Correlation Score: {correlation_score:.3f}") # Output: Correlation Score: 1.000 (perfect correlation)
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    The results of the new correlation metric applied to the example images are shown in @fig:truth_compare:correlation.
    While the results are encouraging in terms of demonstrating the algorithm's capabilities, they unfortunately do not reveal any significant enhancement in comparison to @section:pearson.
    
    It is evident that all scores are comparable to the Pearson coefficient values. This observation aligns with the underlying principle of the algorithm, which is rooted in measuring the correlation between two datasets. 
    This further substantiates the reliability of the Pearson coefficient values as a reliable metric for assessing the performance of the algorithm.

    The results indicate minimal absolute errors in relation to their respective linear fits.
    An examination of @fig:truth_compare:correlation:a and @fig:truth_compare:correlation:c reveals the algorithm's capacity to generate satisfactory outcomes, as evidenced by the normalized MAE and the R2 Score.
    However, it is evident that the fits are not perfect, or rather, do not align with expectations. 
    This deviation can be attributed to the presence of clear outliers in the scatter plot.

    A more compelling comparison can be made by examining the example of @fig:truth_compare:correlation:b.
    In this case, the algorithm's scores consistently fall short of the desired level of satisfaction.
    The issue lies in the fact that, while the scores do reflect a lower quality compared to the other two examples, they do not represent this as effectively as desired.
    This phenomenon can be attributed to the fact that, even in this instance, the mean absolute error (MAE) is not particularly low. 
    The fit itself is not poor; it is merely constructed upon substandard data.
    This phenomenon is more evident in the R2 Score.
    Due to the equitable weighting of the two metrics, the resulting score does not represent the low R2 Score values, and therefore not the low quality of the linear relationship assumption.

    A more substantial problem that can be observed is evident in the result of this example using the Sobel derivative.
    The R2 score in this case, while still comparatively low, demonstrates indications of improvement in comparison with the other derivatives.
    This however, does not stem from an actual improvement in the data. 
    It is an indicator that the data align more closely with a linear relationship.
    However, this is not a favorable outcome, as the linear relationship exhibits an evident anti-correlation with the ground truth data.
    Conversely, a higher score that does not align with the expected outcome is not consistent with the principle of faithfulness to expectation.
    This was previously indicated by the negative Pearson correlation score documented; however, this is no longer represented within this approach.

    In view of the aforementioned issues and the inability to enhance on the Pearson coefficient, the subsequent final analysis of the algorithm's performance will be conducted employing the Pearson coefficient.
    The sole viable enhancement in this section was the more straightforward method for visually depicting the linear correlation between the two datasets.

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