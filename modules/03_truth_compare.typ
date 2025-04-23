#import "@preview/subpar:0.2.0"
#import "../templates/terms.typ": abr

#let truth_compare() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
      width: 100%
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
    It must also again be noted that the RGB data and the nDSM data are not perfectly aligned. 
    Consequently, an attempt to create a ground truth based only on the RGB data would yield a different result than the nDSM data, particularly with regard to the house outlines, where the misalignment becomes quite evident.
    Therefore the ground truth data will mainly be built solely upon the nDSM data, whereby it must be noted that this approach introduces a discrimination against later built analysis on the RGB data.
    This is deemed accceptable because of the assumption that the height information is neccessary for good evaluation anyway, and biasing it here makes sense.

    Nonetheless, it is proposed that a sufficiently accurate ground truth is enough to create a general idea of whether the algorithm is performing in a satisfactory manner.
    Provided that the general structure and number of segments are accurate, the ground truth can be considered sufficiently reliable. 
    This is because minor discrepancies in the output score calculated on the ground truth do not invalidate the algorithm.





    == Segmentation Evaluation

    === Bigger Picture

    @DataCompleteness describes three core factors of important data quality, completeness, accuracy and consistency.
    However, our focus will be on completeness and accuracy, since consistency is not that relevant in the current use case.
    Consistency amongs data sets would also be hard to describe here exactly.
    A way of describing it would be that Segment Anything Model (SAM) receives reliable data across multiple roofs given to it, without mayor drops in their segmentation quality.
    We already tried to identify, whether all types of roofs are inside the dataset, while using the classification by the faulty input data.
    However consistency in this specific case would also mean that the algorithms score can be trusted regardless of roof type.
    As this would create an actual need for many testing examples and extended identification or clasification of our calculated examples, for now it will not be further discussed.
    Therefore the assumption is once again made, that an algorithm which performs well on normal roofs and normal roof type variations will also perform well on other roof types, for example flat roofs, and that normal and flat roofs make out the majority of the dataset.
    Further evaluation on special roofs may be postponed.

    Completeness can be interpreted as two things.
    For one, the entire data set of roofs has to ensure that all relevant types of roofs are represented.
    On the other hand, in this specific example we are rather using it to evaluate each individual segmentation from the algorithm which is to be given to SAM.
    In that sense, completeness means that the calculated segmentation includes the entire actual surfaces.

    Lastly, accuracy is the most important factor in this use case.
    @DataCompleteness2 differentiates between accuracy and reliability.
    While they describe reliability as not in itself contradicting, which could be interpreted as a pixel not being able to be part of multiple surfaces.
    This in not possible in the current algorithm, which is important, however, i still support the description of needing reliable data outputted from the segmentation algorithm in regards to whether we can trust the data to be correct.
    To describe this both factors, i will further only use accuracy or correctness.
    The algorithm has to ensure informational correctness, meaning the expactation is given, that all data identified as roof by the algorithm has to actually be part of the roof.
    Classifying pixels outside the house as roof could cause a big problem, whilest misclassifying one segment's pixels as part of another segment may cause problems, but not as severe ones which are either more easily fixable or may not even be a problem at all.
    Regardless, since misidentifyed roof segments even inside the entire roof structure are problematic, no bias towards either will be introduced, simplyfing the problem to does pixels belonging to the surface map onto exactly one real-world surface.

    ==== Segmentation Evaluation

    Remember, the primary objective of the segmentation calculated here is to provide sufficiently accurate points within each segment to prompt SAM.
    In turn, this means an incomplete segment will still be reduced to a valid point inside the real structure, while an incorrect segment could lead to an invalid point outdide the real structure.
    As this could confuse the model, it is important to ensure that the algorithm is correct, even if it is incomplete.
    Since SAM requires only hints of sufficient quality about the potential locations of surfaces, there is no actual need for the segmentation to be perfect.

    However, creating ground truths for the roofs is too time consuming, not feasible for the current project and in generel the very thing we are trying to avoid.
    Therefore a different approach was chosen.
    The scoring system shown in @scoring is used to evaluate the quality of the segmentation.
    If we trust that scoring system to accurately evaluate the quality of the segmentation, it's input points will be sufficient for further analysis.
    Running the algorithm and evaluating the performance on representaive houses will give us performance metrics on the algorithm, which in turn will give us a good idea on how well the algorithm performs on the given data.
    It must be acknowledged that of course testing the algorithm this way on only a few hand-picked houses may not serve as statistial proof.
    Since however, it is a good tradeof between objective evaluation and only medium effort neccessary, we may assume that the algorithm will perform similarly on other houses.

    Since we are not evaluating data sets but specific comparisons between a geometry representing a calculated surface and one representing a ground truth, we can break down the problem to be analyzed via the statistical metrics of recall and precision.
    Also, since we do have connected geographical structures without complex information structures, the problem can be simplified to be solved wit ha simple confusion matrix.
    This is possible since the tuple of pixel coordinates can be classified as true positives (TP), false positives (FP), and false negatives (FN) in a simple manner.
    @ConfusionMatrix shows such way of calculation for Object Classification, which can be adapted to the current problem.

    - Recall measures the completeness of the segmentation, meaning whether all or how much of the actual roof is covered by the calculated segmentation:
      $ "Recall" = "TP" / ("TP" + "FN") $ <formula:recall>

    - Precision measures the correctness of the segmentation, which answers the question of how accurate positive classifications by the alorithm are:
      $ "Precision" = "TP" / ("TP" + "FP") $ <formula:precision>

    ==== Execution

    While this may sound simple to calculate, the exact calculation must be discussed in further detail.
    There is the possibility of evaluating the entire structure. meaning the combination of all surfaces in regards to the ground truth structure overall.
    This may show us for example whether all pixels of the roof are identified correctly and how many pixel are identified as roof which are not.
    In regards to the actual task however, this is not sufficient, as it tells nothing about identifying indiviual surfaces correctly.
    Therefore, the evaluation must be done on a per-surface basis.
    This means that the recall and precision are calculated for each surface individually and then averaged to get the overall performance of the algorithm.
    The problem thereby is, that not all surfaces will be identified perfectly.
    Some may very well be split apart into two surfaces, because of abnormalies inside the surface being detected on an edge, or for that matter edges in the direction of axes being by nature of higher contrast value, meaning easier for the algorithm to misclassify.
    This in turn leads to the problem of how to evaluate the recall and precision of a surface which is split into two surfaces.

    The easiest and probably best solution is a simple one to one mapping.
    For each ground truth surface, we must find the best calculated surface, determined by highest Intersection over Union (IoU) value.
    This is the best way because of various reasons.
    For one, assuming the algorithm would be perfect, a one to one mapping would be the expected result.
    Since we already decided the minor need for completeness, even relatively low values in that aspect are sufficient, as long as the correctness values are high.
    Having a low completeness may only be a sign that the algorithm splits surfaces too much, which would be a helpful hint, if we were trying to perfect it.

    In general, this is a problem about under- and oversegmentation @underAndOversegmentation @underAndOversegmentation2.
    Oversegmentation in this case means that one of the roof surfaces is split into multiple parts.
    This is not a mayor problem, as long as the parts are not misclassified, however, later we will need to address this problem as it may lead to multiple prompts for the same surface or would create prompts which would become invalid negative prompts for SAM.
    For now this Fragmentation needs to be kept in mind, but will not be algorithmically addressed in the segmentation calculation.
    Later work may try to fix this problem by dynamically merging surfaces and re-calculing the score, looking for improvements.

    The worse case is undersegmentation, which means that multiple roof surfaces are merged into one.
    This creates a wrong assumption about the general roofs part umber as well as may lead to wrong prompts for SAM, which should be avoided in any case.

    Whilest having said that, for general analysis @fig:truth_compare:completeness shows the calculated recall and precision for different numbers of calculated surfaces matched to one ground truth surface.
    It is visible that the recall, here named correctness, is overall quite high, meaning a good accuracy of classified pixel.
    Whilest a perfect score would probably be impossible anyway, the only outlier can be seen in the blue and light brown surfaces on the lower left, where transition between house and ground is not clear.
    An overall high accuracy even in @fig:truth_compare:completeness:d, where up to 10 surfaces are matched to one ground truth surface, is a good sign for the algorithm's performance.
    This means that even if one of the surfaces which could be described as wrong are transformed into SAM input prompts, there should not be a mayor problem in regards to correctness.
    However the problem is that there is no simple way of filtering out such surfaces, as they are not wrong in the sense of being misclassified, but rather in the sense of being split too much.
    One way of fixing this may be actual improvement on the algorithm, however, for now this problem will be ignored.
    There will of course be an effort in fixing this problem when actually doing the prompting, for example by dynamically choosing input prompts by surfaces which are not yet represented by earlier prompts, more on this later.

    To at least say it, the completeness of the surfaces is kind of as expected.
    The biggest improvement can be seen when upping the limit from one match to two, meaning a tendency to at least split surfaces once.
    Most smaller surfaces which are added in the higher limit runs in actuality add little to the resulting structure.
    As they have little impact on the overall score, they are not a mayor concern.
    This is only a problem on some instances, where small connections lead to relevant splitting, but because this is caused by low pixel images and approximations done, fixing this seams fairly unplausable without mayor time investment.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      figure(image("../figures/truth_compare/completeness/1.png"), caption: [
        Evaluation when enforcing exact 1 to 1 Matches
      ]), <fig:truth_compare:completeness:a>,
      figure(image("../figures/truth_compare/completeness/2.png"), caption: [
        Matching 2 Calculated Surfaces to 1 Ground Truth
      ]), <fig:truth_compare:completeness:b>,
      figure(image("../figures/truth_compare/completeness/4.png"), caption: [
        Matching 4 Calculated Surfaces to 1 Ground Truth
      ]), <fig:truth_compare:completeness:c>,
      figure(image("../figures/truth_compare/completeness/10.png"), caption: [
        Matching up to 10 Calculated Surfaces to 1 Ground Truth
      ]), <fig:truth_compare:completeness:d>,
      caption: [
        Graphical representation of the calculated recall and precision for different numbers of calculated surfaces matched to one ground truth surface.
      ],
      label: <fig:truth_compare:completeness>,
    )




    ```python
    def score(generated_surfaces, true_surfaces, max_surfaces=1):
        # Flatten original surfaces for faster pixel lookup
        original_surface_pixels = set()
        for surface in generated_surfaces:
            original_surface_pixels.update(surface)

        # For each Surface find out which Ground Truth it belongs to
        match_list = list()
        for surface in generated_surfaces:
            best_iou = 0
            best_match = None
            for truth in true_surfaces:
                iou = calculate_iou(surface, truth)
                if iou > best_iou:
                    best_iou = iou
                    best_match = truth
            match_list.append((surface, best_match, best_iou))

        # Calculate TP, FP and FN using max_surfaces as cut-off
        tp, fp, fn = 0, 0, 0
        for gt_surface in true_surfaces:
            best_matches = []
            for surface, hit, iou in match_list:
                if hit == gt_surface:
                    best_matches.append((surface, iou))
            best_matches.sort(key=lambda item: item[1], reverse=True)
            best_matches = best_matches[:max_surfaces]

            bm_pixel = set()
            for match, iou in best_matches:
                bm_pixel.update(match)

            gt_pixel = set(gt_surface)
            tp += len(gt_pixel & bm_pixel)
            fp += len(bm_pixel - gt_pixel)
            fn += len(gt_pixel - bm_pixel)

        # Apply recall/precision formulae
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0 

        return calculate_fbeta_score(precision, recall)
    ```













    === Comparing Segments via IOU
    ```python
    def calculate_iou(seg1, seg2):
      set1, set2 = set(seg1), set(seg2)
      intersection = len(set1 & set2)
      union = len(set1 | set2)
      return intersection / union if union > 0 else 0
    ```

    @iou1, @iou2



    === Creating the final score via the Fß Score method

    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ F_1 = ("precision" * "recall") / 2 $ <formula:f1>
    $ F_ß = ( 1 + ß² ) * ("precision" * "recall") / ((ß² * "precision") + "recall") $ <formula:fß>

    A useful metric for combining the two scores of recall and precision is the F1 score, shown in @formula:f1. 
    This score is calculated by dividing the sum of the given scores by two to create an output score.
    As previously mentioned, our objective is not to achieve equal prioritization of recall, which is often referred to as "completeness," and precision, which is often referred to as "correctness."
    Consequently, the formula presented in @formula:fß will be employed.
    The Fß score is a generalization of the F1 score that incorporates a weighting coefficient, ß, into the formula @Fß. 
    This modification enables the dynamic prioritization of either input.

    Given the necessity to prioritize precision, the $F_0.5$ score will be employed, representing the $F_ß$ score when $ß = 0.5$.
    The calculation of these values for exact matches results in a score of $F_0.5≈0.887$. This figure offers a clear illustration of the bias, as an even valuation would yield a score of approximately $F_1≈0.75$. This observation serves to underscore the impact of the bias.

    While it may seem logical to exclude the completeness from this calculation altogether, it is useful for enhancing the comparability with the scoring system.
    In essence, our objective is to utilize this as a metric to assess the reliability of the scoring system. 
    Given that the algorithm employs a positive and negative scoring system, this approach is a logical one.
    Nonetheless, it could be argued that the elimination of the negative score could similarly yield a non negative outcome, as the theoretical irrelevance of missing pixels was elucidated at the beginning of this chapter.
    Notwithstanding, the decision was made to not exclude recall, using the $F_0.5$ score when calculating the final scores out of positive and negative scores.
    This introduces a bias in favor of surfaces being correct and mitigates the impact of missing surface area.
    
    ```python
    def calculate_fbeta_score(precision, recall, beta=0.5):
      if precision == 0 or recall == 0:
        return 0
      return (1 + beta**2) * (precision * recall) / (beta**2 * precision + recall)
    ```
    
    === Using the Hungarian Matching Algorithm for Scores
    Subsequent to the completion of the task of manually creating the scores, as delineated in the preceding section, this section will briefly detail the process of reducing and overhauling the code while refactoring.
    Despite the absence of a fundamental shift in the overarching concept, certain components have undergone an adaptation process, incorporating the utilization of library functions and well-established algorithms, as well as finding and fixing errors which become appearant in comparison.

    Conducting online research revealed that constraining the matching of generated segments and ground truth segments to being strictly 1-to-1 is equivalent to using the Hungarian Matching Algorithm @hungarian1.
    The necessity of maintaining a list to precisely match each surface with a single ground truth segment, with the intention of subsequently selecting the most suitable one, will been rendered obsolete.
    The Hungarian algorithm is a computational optimization technique that addresses the assignment problem in polynomial time. 
    It can be utilized to identify the optimal assignment of generated segments to ground truth segments by cost minimization @hungarian2.
    A two-dimensional matrix of size $n*m$ is employed, wherein $n$ denotes the number of predicted segments and $m$ signifies the number of segments in the ground truth data. This matrix contains all IOU values.
    The algorithm's function is to calculate the optimal matching pairs between the two sets of segments.
    Therefore, the IOU matrix is simply inverted so that the task becomes minimizing, since typically, an IOU would need to be maximized.

    ```python
    def hungarian_matching(prediction, truth):
      cost_matrix = np.zeros((len(prediction), len(truth)))
      for i, seg1 in enumerate(prediction):
          for j, seg2 in enumerate(truth):
              cost_matrix[i,j] = (1 - calculate_iou(seg1, seg2))
      row_ind, col_ind = linear_sum_assignment(cost_matrix)

      matches = []
      matched_truth = set()
      for i, j in zip(row_ind, col_ind):
          if cost_matrix[i,j] != 1:
              matches.append((i, j))
              matched_truth.add(j)

      # Find unmatched segments
      unmatched1 = [i for i in range(len(prediction)) if i not in row_ind]
      unmatched2 = [j for j in range(len(truth)) if j not in matched_truth]

      return matches, unmatched1, unmatched2
    ```

    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../figures/truth_compare/hungarian/error1.png")),
      figure(image("../figures/truth_compare/hungarian/error2.png")),
      figure(image("../figures/truth_compare/hungarian/error3.png")),
      caption: [
        The Comparison between old scoring system and new clearly show a mismatch in precision calculation. 
        However, no example was found in which this influenced the final outcome of choosing a segmentation.
      ],
      label: <fig:truth_compare:hungarian_error>,
    )

    The Hungarian algorithm aligns with our objectives, demonstrating enhanced optimization compared to the self-implementation approach due to its status as established library code.
    Additionally, the algorithm inherently produces surfaces that have not been mapped. 
    These surfaces may not align with any truth segments, or may be outscored by other surfaces.
    The availability of these surfaces facilitates effective visualization of the cases, thereby enabling subsequent evaluation.

    The scoring system remains relatively stable.
    The calculation of precision and recall remains unchanged; however, the calculation of true positive (TP), false positive (FP), and false negative (FN) is now performed using the matches from the Hungarian algorithm directly as well as the unmatched segments.

    ```python
    def score(prediction, truth, beta=0.5):
      matches, unmatched1, unmatched2 = hungarian_matching(prediction, truth)

      if not matches:
          return 0.0

      # Initialize counts
      tp, fp, fn = 0, 0, 0

      # Process matched pairs (account for partial matches via IoU)
      for i, j in matches:
          seg1, seg2 = prediction[i], truth[j]
          intersection = len(set(seg1) & set(seg2))

          tp += intersection
          fp += len(seg1) - intersection  # Predicted but unmatched
          fn += len(seg2) - intersection  # True but unmatched

      # Add unmatched ground truth
      fn += sum(len(truth[j]) for j in unmatched2)
      # Add unmatched predictions
      fp += sum(len(prediction[i]) for i in unmatched1)

      # Calculate precision and recall
      precision = tp / (tp + fp) if (tp + fp) > 0 else 0
      recall = tp / (tp + fn) if (tp + fn) > 0 else 0

      # Compute Fβ-score
      return calculate_fbeta_score(precision, recall)
    ```

    However, a notable distinction between the two implementations lies in the methodology employed for handling unmatched segments.
    As illustrated by the implementation in @fig:truth_compare:hungarian_error, there is a discrepancy in the calculation of scores between the approaches.
    While the two approaches are similar in general, the new implementation utilizes unmatched segments to calculate false positives and false negatives, a feature not present in the older approach.
    Initially, an unmatched predicted surface was excluded from the false positive calculation due to the negligible impact of undersegmentation on the algorithm's performance.
    The algorithm would only need to address the issue of oversegmentation, as this would result in fewer prompts than the number of truth surfaces.
    In the subsequent implementation, however, this concept was not utilized due to a reevaluation of the approach.
    The objective is to ascertain the validity of the concept in relation to the ground truth. 
    Consequently, the penalization of erroneous surfaces is imperative to ensure the integrity of this endeavor.

    #figure(
      image("../figures/truth_compare/hungarian/hungary_compare.png"), caption: [
      New visual representation of matching the segments.
    ]), <fig:truth_compare:hungarian_compare:a>

    The statistics presented in @fig:truth_compare:hungarian_statistics illustrate the disparities between the two implementations with respect to performance metrics.
    The first image displays the percentage difference between the two calculations.
    The range of these values extends from -16 to 0 percent.
    A negative value in this context indicates that the score generated from the new implementation is lower than the one derived from the prior implementation.
    This outcome is consistent with the established pattern, as the solution resolves a discrepancy that systematically overestimated the precision.

    As demonstrated by @fig:truth_compare:hungarian_statistics:b, the new implementation has been shown to result in a relative time savings.
    The values were measured by taking the average of 100 executions of the scoring algorithms per entry.
    A comparative analysis revealed that, in select instances, the novel algorithm exhibited a maximum decrease in processing time of up to 5%. 
    Nevertheless, on average, the new implementation demonstrated a 10% reduction in processing time.
    The absolute times exhibited a range from 0.1 to 0.3 seconds, contingent, naturally, on the number of surfaces.
    The enhancement in performance, accompanied by the rectification of a scoring system error, signifies a favorable outcome, validating the value of this alteration.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../figures/truth_compare/hungarian/error_statistic.png"), caption: [
        Percentual Error between the two Calculations.
      ]), <fig:truth_compare:hungarian_statistics:a>,
      figure(image("../figures/truth_compare/hungarian/hungarian_diff.png"), caption: [
        Relative Time Saved by using the new Implementation.
      ]), <fig:truth_compare:hungarian_statistics:b>,
      caption: [
        Statistical comparison between using the original scoring variant and using the Hungarian Matching.
      ],
      label: <fig:truth_compare:hungarian_statistics>,
    )

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
    Specifically, the following metrics are of relevance: the #abr("MAE"), the #abr("MSE"), the #abr("RMSE"), and the R2 score.

    The #abr("MAE"), #abr("MSE"), and the #abr("RMSE") are all error metrics. These metrics directly measure the differences between the values of two datasets, under the assumption that the two datasets are directly correlated 1-to-1.
    The R2 score is a measure of the extent to which the data aligns with a linear model, also referred to as the coefficient of determination.
    This range extends from $(-infinity, 1]$, with 1 representing a perfect fit and negative values denoting a lack of fit for the data within the linear model.

    The #abr("MAE") is calculated by taking the absolute difference between the two datasets and averaging it (see @formula:mae). The #abr("MSE") is calculated by taking the squared difference between the two datasets and averaging it (see @formula:mse). The #abr("RMSE") is calculated by taking the square root of the MSE (see @formula:rmse).
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