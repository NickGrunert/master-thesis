#import "@preview/subpar:0.2.0"

#let truth_compare(abr) = {
  text(lang:"en")[
    == Evaluation Against Ground Truth <section:truth_compare>
    It is essential to recall that the primary objective of the segmentation calculated here is to provide sufficiently accurate points within each segment to prompt #abr("SAM").
    Therefore, an incomplete segment will be reduced to a valid point within the real structure. 
    Conversely, an incorrect segment could lead to an invalid point outside the real structure.
    Given the potential for such discrepancies to disrupt the model's functionality, it is imperative to ascertain the integrity of the algorithm, even in the event of its partiality.
    As #abr("SAM") operates on the principle of detecting surfaces with only minimal indications of their potential locations, the necessity for precise segmentation does not arise.

    The scoring system delineated in @section:scoring is employed to evaluate the quality of the segmentation.
    The assumption that the scoring system can accurately evaluate the quality of segmentation is fundamental to this study. 
    The system's input points will be sufficient for further analysis, provided that this assumption is valid.

    Evaluation and validation of algorithms requires the creation of objective data for the purpose of comparison, ground truth data.
    This section delineates the methodology employed to generate such and the subsequent development of a scoring system to assess the efficacy of the algorithm. 
    The establishment of objective reference data facilitates a quantitative comparison between the algorithm's output and expected results. 
    The metrics will provide a meaningful assessment of the algorithm's accuracy and reliability when applied to the dataset of houses.

    It must be acknowledged that the efficacy of the algorithm can only be ascertained through a rigorous and extensive testing process. 
    Conducting a limited evaluation on a small number of hand-picked houses does not provide sufficient statistical evidence to draw definitive conclusions.
    However, given the favorable trade-off between objective evaluation and minimal time investment required, it is reasonable to infer that the algorithm will demonstrate comparable performance across other houses.

    === Ground Truth Creation <section:ground_truth>
    The evaluation will be based on a set of twenty ground truth images, which were derived from images corresponding to the 60th percentile of the entire image dataset sorted by roof area.
    This selection was made on the basis that these models adequately represent the data overall. 
    They are sufficiently small to be processed in a reasonable timeframe while still exhibiting sufficient complexity.
    A more expansive roof composed of a greater quantity of diminutive, intricate surface segments would not generate a sufficient amount of information to justify the investment of time required to manually construct ground truths.
    Furthermore, this particular section of the data set encompasses a diverse array of roof shapes, ranging from simple to complex designs, primarily consisting of normal roofs, in addition to a flat roof with a relatively uncomplicated design.

    @GroundTruth1 elaborates on the issues that emerge during the process of data generation.
    As previously discussed, the images currently under consideration are characterised by suboptimal pixel quality. 
    This deficiency manifests particularly in thin roof regions, where the delineation of the edge is rendered indistinct.
    Additionally, certain edges are challenging to discern with the naked eye, and they are often imperceptible in both the #abr("nDSM") and RGB data.
    However, these edges become clearly visible when utilising the derivative and colouring the image with this data.
    This introduces an additional layer of complexity to the process of generating the ground truth segmentations.
    It must also again be noted that the RGB data and the #abr("nDSM") data are not perfectly aligned.
    Consequently, an attempt to create a ground truth based only on the RGB data would yield a different result than the #abr("nDSM") data, particularly with regard to the house outlines, where the misalignment becomes quite evident.
    The ground truth data will therefore mainly be built solely upon the #abr("nDSM") data, whereby it must be noted that this approach introduces a discrimination against later analysis happening on the RGB data.
    This is considered an acceptable practice due to the assumption that the height information is necessary for a comprehensive evaluation, and biasing it at this stage is a logical decision.
    
    As illustrated by @fig:truth_compare:truth_example, four of the twenty images are displayed, along with their respective derivative images and the ground truth segmentations.
    It is evident that certain challenges have emerged in relation to this matter.
    Due to the insufficient contrast present in the #abr("nDSM") images and data, precise identification of the subject was not possible by hand. 
    Consequently, the derivative images were saved in advance to ensure the accuracy of subsequent analysis.
    This facilitates a more precise understanding of the roof segments' geometry than would be possible with other data sources.

    The process of deriving these values may not always result in the creation of smooth segments, as illustrated in the last shown example in @fig:truth_compare:truth_example.
    The Sobel filter is the derivative employed in this context.
    The experimental results indicated that these errors manifested in a seemingly random manner in a subset of the image data.
    It appears that the employment of the derivative, which is known to yield the optimal outcome in @section:algorithm, serves to mitigate this effect.
    This establishes the hypothesis that the Sobel method may be suboptimal, although this remains to be proven.
    This risk is nevertheless deemed acceptable for the time being. The @section:ablation:derivative will address the selection of the appropriate derivative in greater detail.

    #subpar.grid(
      columns: (1fr, 1fr, 1fr),
      gutter: 1mm,
      figure(image("../data/6/1/image.png", height: 15.5%)),
      figure(image("../data/6/1/helper/derivative.png", height: 15.5%)),
      figure(image("../data/6/1/truth.png", height: 15.5%)),
      figure(image("../data/6/5/image.png", height: 23%)),
      figure(image("../data/6/5/helper/derivative.png", height: 23%)),
      figure(image("../data/6/5/truth.png", height: 23%)),
      figure(image("../data/6/13/image.png", height: 27%)),
      figure(image("../data/6/13/helper/derivative.png", height: 27%)),
      figure(image("../data/6/13/truth.png", height: 27%)),
      figure(image("../data/6/19/image.png", height: 18.5%)),
      figure(image("../data/6/19/helper/derivative.png", height: 18.5%)),
      figure(image("../data/6/19/truth.png", height: 18.5%)),
      caption: [
        Images with their respective derivative image and ground truth
      ],
      label: <fig:truth_compare:truth_example>,
    )

    Nonetheless, it is proposed that a sufficiently accurate ground truth is enough to create a general idea of whether the algorithm is performing in a satisfactory manner.
    Provided that the general structure and number of segments are accurate, the ground truth can be considered sufficiently reliable. 
    Minor discrepancies in the outputted truth score do not invalidate the algorithm.


    === Evaluation of Individual Segmentations
    This section will provide a detailed exposition of the methodology that was employed to evaluate individual segments.
    The following discussion will focus on specific components, which will ultimately result in the formulation of a score function.
    This function will be utilised to assess the predicted segments against the established ground truth data.

    ==== Comparing Segments via #abr("IoU")
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "IoU"_"A,B" = ("A" \u{2229} "B") / ("A" #sym.union "B") $ <formula:iou>
    $ "IoU" = "TP" / ("TP" + "FP" + "FN") $ <formula:iou2>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    A widely accepted approach for the comparison of two segments is the calculation of the #abr("IoU") @iou1 @iou2.
    It is generally recognised as being computationally efficient and has become a staple component in the realm of computer vision workflows.
    The #abr("IoU") metric is a quantitative measure of the overlap between two segments.
    Although the algorithm is frequently employed for bounding box comparisons @iou3, it is also capable of performing a pixel-wise set comparison on the two surfaces.
    The resulting score is calculated by dividing the area of intersection by the area of union, as demonstrated in @formula:iou.
    This calculation provides a quantitative metric that measures the degree of similarity between two segments. 
    A value of 1 indicates a perfect match, while a value of 0 indicates no overlap.
    Furthermore, it imposes a penalty on either of the two segments if their respective areas fall outside the boundaries of the other segment.

    It is acknowledged that @formula:iou2 is an alternative calculation approach that does not operate via set operations but via the confusion matrix.
    The implementation of this would, in principle, be a rational course of action, given the subsequent section's introduction of the metrics within the formula. However, this approach was not adopted, as it would not lead to an improvement of the algorithms calculational efficiency that would rectify the work required to realise it.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The following code shows a simple implementation of the #abr("IoU") calculation.
    The individual segments are first redefined as sets for computational efficiency, since it allow for faster membership testing and set operations via binary operations.
    ```python
    def calculate_iou(seg1, seg2):
      set1, set2 = set(seg1), set(seg2)
      intersection = len(set1 & set2)
      union = len(set1 | set2)
      return intersection / union if union > 0 else 0
    ```

    ==== Calculating Recall and Precision
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "Accuracy" = ("TP" + "TN") / ("TP" + "TN" + "FP" + "FN") $ <formula:accuracy>
    $ "Recall" = "TP" / ("TP" + "FN") $ <formula:recall>
    $ "Precision" = "TP" / ("TP" + "FP") $ <formula:precision>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    There is more than one way to define data quality and it's fundamental components; one of such definitions being completeness, accuracy, and consistency @DataCompleteness.
    However, our primary concern at this stage is to prioritise completeness and accuracy, given the relatively low priority accorded to consistency in the current use case.

    The degree of consistency will not be discussed further in this text, since doing so would entail an evaluation of the adequacy of the original geographical division and the representativeness of the buildings contained therein with respect to universal building types.
    It can be stated, with a reasonable degree of certainty, that the data is assumed to demonstrate a sufficient degree of variability in terms of complexity with regard to typical roof types.
    The degree of consistency among the data sets would be challenging to precisely delineate in this context.
    An initial investigation was conducted to ascertain the presence of all roof types within the dataset.
    However, in this particular instance, maintaining consistency would also imply that the algorithms' scores can be relied upon, irrespective of the roof type.
    While the present study does not encompass extensive testing of the algorithm's performance on various roof types, the testing examples do include a few non-normal roof types, on which the performance will be measured briefly.
    For instance, given the prevalence of flat roofs in the input data and their relatively uncomplicated structural nature, the successful performance on a limited number of instances can be extrapolated to infer the efficacy on the entire dataset.
    This assertion is equally applicable to other roof types, given the substantial comparability of standard roof components.

    As we are not evaluating data sets but rather specific comparisons between a geometry representing a calculated surface and one representing a ground truth, it is possible to break down the problem to be analysed via statistical metrics.
    Additionally, given the existence of interconnected geographical structures devoid of intricate information systems, the problem can be streamlined for resolution through the utilisation of a confusion matrix.
    Object detection normally uses simple bounding box checks for this calculation @ConfusionMatrix.
    In the context of this work, instead of bounding boxes, each pixel coordinate can easily be categorised as #abr("TP"), #abr("FP"), and #abr("FN") after matching predicted segments to ground truth segments.

    The three main metrics applicable for analysing in such a manner are accuracy, recall, and precision @DataCompleteness3.
    The utilisation of accuracy, as demonstrated in @formula:accuracy, would, however, not be advantageous in this instance. 
    While the calculation of the number of true negatives is possible, its practical application is limited.
    The issue with this approach is that the algorithm is not attempting to differentiate between pixels as belonging to a roof or not, but rather is focused on the classification of each individual roof segment.
    Nonetheless, it would be a possibility to evaluate the mask quality, which is utilised to filter out segments after edge detection, such that only roof segments remain.

    In this particular instance, the completeness will be evaluated using the recall metric, which is defined as the ratio of true positives to the sum of true positives and false negatives, as shown in @formula:recall.
    This approach quantifies the proportion of correctly identified pixels in context to the entire ground truth surface, thereby estimating the completeness of the prediction.

    The Calculation of the precision metric is demonstrated in @formula:precision; making use of true and false positives.
    The metric will be employed to assess the correctness of the prediction and is therefore also a measure of accuracy.
    It is the ratio of correctly identified pixels to the total number of pixels predicted as part of the surface. 
    Consequently, the value can either increase or decrease, contingent on the number of pixels that are not part of the surface but are predicted as such.
    In summary, the definition provides a quantitative measure of the reliability of a positive prediction.
    As previously stated, this is the initial and most imperative directive for the algorithm to fulfill.



    While this calculation may appear straightforward, a more thorough discussion is necessary to ensure its proper execution.
    The evaluation of the entire structure, encompassing the combination of all surfaces in relation to the ground truth structure, is a possibility.
    This may demonstrate whether the identification of pixels on the roof is accurate, and if so, the number of non-roof pixel.
    With regard to the task at hand, however, this proves inadequate, as it fails to address the need to accurately identify each individual surface.
    Consequently, the evaluation process must be conducted on a per-surface basis.
    This approach entails the calculation of recall and precision for each surface individually, followed by an aggregation of these values to obtain the algorithm's resulting score.
    The issue arises from the fact that not all surfaces will be identified with absolute precision.
    In some cases, surfaces may be subdivided into two surfaces due to the presence of abnormalities detected along an edge. 
    Alternatively, derivatives oriented along the axes may exhibit higher contrast values, which can be more readily misclassified as edges by the algorithm.
    This, in turn, gives rise to the issue of evaluating the recall and precision of a surface that has been divided into two surfaces.

    A problem exists regarding the matching of segments to ground truths.
    There are two variations of this, undersegmentation and oversegmentation @underAndOversegmentation @underAndOversegmentation2.
    The latter refers to the division of a single roof surface into multiple predicted segments.
    Regardless, this issue is not a significant concern, provided each individual component for itself is not misclassified. 
    However, it is necessary to address this matter at a later stage, as it may result in the generation of multiple prompts for a given surface or the creation of invalid negative prompts for #abr("SAM").
    This is not problematic for the generation of exclusively positive input points, as reiterating the same mask does not constitute an error.
    At this stage, it is imperative to bear in mind the issue of fragmentation. 
    However, it should be noted that this will not be addressed through the implementation of an algorithm in the calculation of segmentation.
    Subsequent work may attempt to rectify this issue by dynamically merging surfaces and recalculating the score to identify areas for enhancement.

    A more significant concern pertains to the issue of undersegmentation, which occurs when multiple ground truth roof surfaces are combined into one single prediction.
    This erroneous assumption can result in inaccurate estimations of the number of roof components, which, in turn, may prompt erroneous input prompts for #abr("SAM"). 
    It is imperative to refrain from such input prompts under any circumstances.
    The prior scoring algorithm, which employs the plateau algorithm, imposes a significant penalty on this issue, incentivising the algorithm to avoid it.
    This scoring system is not designed to perform the aforementioned function, as doing so would introduce significant complexity, since, for example, the #abr("IoU") does not directly account for #abr("FP").
    @section:fß outlines an approach to address this issue to a certain extent by placing a greater emphasis on precision over recall. 
    In essence, it penalises #abr("FP") to a greater extent than #abr("FN") when calculating the score.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    For each predicted surface, the algorithm identifies the ground truth segment with the highest #abr("IoU") value.
    The system under consideration enables the matching of multiple segments to a single ground truth segment.
    The calculation of #abr("TP"), #abr("FP"), and #abr("FN") values is contingent upon the aforementioned matching of the algorithm.

    ```python
    def score(generated_surfaces, true_surfaces, max_surfaces=1):
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

        # To be replaced by: calculate_fbeta_score(precision, recall)
        return (recall + precision) / 2
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      figure(image("../figures/truth_compare/completeness/1.png")), <fig:truth_compare:completeness:a>,
      figure(image("../figures/truth_compare/completeness/2.png")), <fig:truth_compare:completeness:b>,
      figure(image("../figures/truth_compare/completeness/4.png")), <fig:truth_compare:completeness:c>,
      figure(image("../figures/truth_compare/completeness/10.png")), <fig:truth_compare:completeness:d>,
      caption: [
        Different n-to-1 relations from generated segments to ground truth
      ],
      label: <fig:truth_compare:completeness>,
    )

    @fig:truth_compare:completeness shows the results of an experiment in which the recall and precision were calculated for different numbers of predicted surfaces matched to one ground truth surface.
    It is evident that the recall, here defined as correctness, is notably high, indicating a commendable accuracy in the classification of pixels.
    Although attaining a perfect score is arguably unfeasible, the sole outlier is discernible in the blue and light brown surfaces located in the lower left corner. 
    This area exhibits ambiguity in the delineation between the house and the ground, potentially compromising the clarity of the transition.

    The algorithm's high accuracy, even when using up to 10 surfaces matched onto one ground truth surface, indicates its good performance.
    Therefore, in the event that one of the surfaces classified as incorrect is converted into a #abr("SAM") input prompt, it is expected that there will not be a significant issue with regard to the integrity of the data.
    It is notable that a straightforward method for filtering out such surfaces is lacking.
    These surfaces are not erroneous in the sense of being misclassified; rather, they are excessively fragmented.
    The implementation of improvements to the algorithm, or the identification of more suitable hyperparameters for the algorithm, has been demonstrated to result in a significant reduction in the impact of this issue.
    
    It can be noted that the completeness of the surfaces is consistent with the expected level of complexity.
    The most significant enhancement is observed when increasing the limit from one match to two, indicating an unfortunate propensity to at least divide surfaces once.
    In the majority of cases, the incorporation of smaller surfaces when utilising high limits results in only a marginal contribution to the overall structure.
    The impact of these elements on the overall score is negligible; therefore, they do not warrant significant concern.
    The issue under discussion manifests itself in specific instances only, wherein thin connections result in the division of subparts.
    Once more, a thorough investigation into the performance implications of the hyperparameters may potentially diminish the consequences of the loss of thin roof components.

    ==== Creating the final score via the $F_ß$ Score method <section:fß>
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ F_1 = ("precision" * "recall") / 2 $ <formula:f1>
    $ F_ß = ( 1 + ß² ) * ("precision" * "recall") / ((ß² * "precision") + "recall") $ <formula:fß>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    A useful metric for combining the two scores of recall and precision is the F1 score, shown in @formula:f1. 
    This score is calculated by dividing the sum of the given scores by two to create an output score.
    As previously mentioned, our objective is not to achieve equal prioritisation of recall, which is often referred to as "completeness," and precision, which is often referred to as "correctness."
    Consequently, the formula presented in @formula:fß will be employed.
    The $F_ß$ score is a generalisation of the F1 score that incorporates a weighting coefficient, ß, into the formula @Fß. 
    This modification enables the dynamic prioritisation of either input.

    Given the necessity to prioritise precision, the $F_0.5$ score will be employed, representing the $F_ß$ score when $ß = 0.5$.
    Executed on the example segmentation from @fig:truth_compare:completeness:a the difference in resulting score is $F_0.5≈0.887$ compared to $F_1≈0.75$, which clearly illustrates that this change indeed has the expected impact of biasing towards the recall metric.

    While it may seem logical to exclude the completeness from this calculation altogether, it is useful for enhancing the comparability with the scoring system.
    In essence, our objective is to utilise this as a metric to assess the reliability of the scoring system. 
    Given that the algorithm employs a positive and negative scoring system, this approach is a logical one.
    Nevertheless, it could be argued that the elimination of the negative score could similarly yield a non-negative outcome, as the theoretical irrelevance of missing pixels was discussed at the beginning of this chapter.
    However, the decision was taken not to exclude recall and to continue using the $F_0.5$ score when calculating the final scores out of positive and negative scores.
    This introduces a bias in favour of surfaces being correct and mitigates the impact of missing surface area.
    
    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    ```python
    def calculate_fbeta_score(precision, recall, beta=0.5):
      if precision == 0 or recall == 0:
        return 0
      return (1 + beta**2) * (precision * recall) / (beta**2 * precision + recall)
    ```
    
    ==== Using the Hungarian Matching Algorithm for Scores
    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    The objective of this section is twofold: first, to reduce the scoring code, and second, to overhaul the implementation of the scoring algorithm. The latter will be achieved by using less manually created methods and instead employing novel algorithms and library functions.
    Despite the absence of a fundamental shift in the overarching concept, certain components have undergone an adaptation process, incorporating the utilisation of library functions and well-established algorithms, as well as finding and fixing errors which become apparent in comparison.

    Constraining the matching of generated segments and ground truth segments to being strictly 1-to-1 is essentially equivalent to using the #abr("HMA"), also called the Kuhn-Munkres algorithm @hungarian1.
    The #abr("HMA") is a computational optimisation technique that addresses the assignment problem in polynomial time. 
    It can be utilised to identify the optimal assignment of predicted segments to ground truth segments @hungarian2.
    A two-dimensional matrix of size $n*m$ is employed, where $n$ denotes the number of predicted segments and $m$ denotes the number of segments in the ground truth data.
    This matrix contains all #abr("IoU") values.
    The purpose of the algorithm is to calculate the optimal matching pairs between the two sets of segments.
    In order to accomplish this objective, it is necessary to invert the #abr("IoU") matrix. 
    This is because, in the typical case, the #abr("IoU") would need to be maximised; however, in this instance, the objective is to minimise the scores.

    The #abr("HMA") aligns with our objectives, demonstrating enhanced optimisation compared to the self-implementation approach due to its status as established library code.
    Additionally, the algorithm inherently produces surfaces that have not been mapped. 
    These surfaces may not align with any truth segments, or may be outscored by other surfaces.
    The availability of these surfaces facilitates effective visualisation of the cases, thereby enabling subsequent evaluation.

    #heading(depth: 5, numbering: none, bookmarked: false)[Comparison]
    The scoring function remains relatively stable.
    The calculation of precision and recall remains unchanged; however, the calculation of #abr("TP"), #abr("FP"), and #abr("FN") is now performed using the matches from the #abr("HMA") directly as well as the unmatched segments.

    However, a notable distinction between the two implementations lies in the methodology employed for handling unmatched segments.
    As illustrated by the implementation in @fig:truth_compare:hungarian_error, there is a discrepancy in the calculation of scores between the approaches.
    While the two approaches are similar in general, the new implementation utilises unmatched segments to calculate #abr("FP") and #abr("FN"), a feature not present in the older approach.
    Initially, an unmatched predicted surface was excluded from the #abr("FP") calculation due to the negligible impact of oversegmentation on the algorithm's performance.
    The algorithm would only need to address the issue of undersegmentation, as this would result in fewer prompts than the number of truth surfaces.
    In the subsequent implementation using the #abr("HMA"), however, this concept is no longer utilised due to reevaluation of the approach.
    The objective is to ascertain the validity of the concept in relation to the ground truth. 
    Consequently, the penalisation of erroneous surfaces in terms of undersegmentation is required to ensure the integrity of this endeavor.
    In the alternative, the score of segmentations could be overestimated to a considerable degree.


    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../figures/truth_compare/hungarian/error1.png")),
      figure(image("../figures/truth_compare/hungarian/error2.png")),
      figure(image("../figures/truth_compare/hungarian/error3.png")),
      caption: [
        Mismatch in precision between old and new scoring
      ],
      label: <fig:truth_compare:hungarian_error>,
    )

    As demonstrated by @fig:truth_compare:hungarian_compare, a new visualisation method has been developed for the purpose of illustrating the handling of segments.
    The absence of matches for two ground truth segments is readily apparent.
    It has moreover been determined that the unmatched segments are attributable to the fact that the algorithm created one large segment, which can ultimately be matched with a single one of the three real segments that compose it, the largest one by pixel length.
    Analysis reveals that the experiment's failure can be attributed to an inadequate adjustment of the canny values. 
    These values were not sufficiently adjusted to create an edge between the segments.

    #figure(
      image("../figures/truth_compare/hungarian/hungary_compare.png"), caption: [
      New visual representation of matching the segments
    ]) <fig:truth_compare:hungarian_compare>

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
        Percentual score difference
      ]), <fig:truth_compare:hungarian_statistics:a>,
      figure(image("../figures/truth_compare/hungarian/hungarian_diff.png"), caption: [
        Relative time saved
      ]), <fig:truth_compare:hungarian_statistics:b>,
      caption: [
        Comparison between the original algorithm and the #abr("HMA") for scoring
      ],
      label: <fig:truth_compare:hungarian_statistics>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Hungarian Matching Algorithm Code]
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

    #pagebreak()
    #heading(depth: 5, numbering: none, bookmarked: false)[Updated Scoring Code]
    ```python
    def score(prediction, truth, beta=0.5):
      matches, unmatched1, unmatched2 = hungarian_matching(prediction, truth)

      if not matches:
          return 0.0

      # Initialise counts
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



    === Metric-Based Evaluation
    It is hypothesised that the resulting score from the plateau algorithm will correlate with the results of the ground truth evaluation.
    This subsection will explore that correlation in detail, in order to prove the validity of the plateau algorithm's score generation to be used even in the absence of ground truth.

    Each individual approach has been developed by incorporating the lessons learned from the results of the previous approaches and striving to improve upon them.
    Consequently, the ensuing sections are dedicated to the following: the presentation of formulae for calculating the metric; an exposition of the rationale behind why it is used; the presentation of example results; and a discussion of the lessons learned.
    The results for each metric will be demonstrated on the three example houses illustrated in @fig:truth_compare:examples.

    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../data/6/10/image.png"), caption: [
        Example A.
      ]), <fig:truth_compare:examples:a>,
      figure(image("../data/6/18/image.png", height: 17.5%), caption: [
        Example B.
      ]), <fig:truth_compare:examples:b>,
      figure(image("../data/6/16/image.png", height: 17.5%), caption: [
        Example C.
      ]), <fig:truth_compare:examples:c>,
      caption: [
        Three examples houses for the metrics to be applied to
      ],
      label: <fig:truth_compare:examples>,
    )

    A limitation common to all subsections, particularly the first, is that they are based on an insufficient number of data points.
    The precise number of data points required for conducting an accurate statistical analysis of the correlation is dependent upon the anticipated magnitude of the correlation @correlation1.
    Initially, the outcomes were split according to the methodology employed in calculating the derivative. 
    This classification system did not encompass data points pertaining to the variation in filter sizes utilised in the Gaussian Blurring process.
    The consequence of this phenomenon was an insufficient number of data points, which, due to excessive clustering, yielded good results, but failed to yield substantial correlation.
    Consequently, the experiment variables were expanded to include the following:
    The clipping values were subjected to testing within the range of zero to ten percent.
    In the context of the Gaussian Blurring process, three distinct kernel sizes were employed, and a total of seven configurations were examined for the lower and upper threshold of the Canny algorithm.
    This resulted in a total of 210 data points for each of Sobel, Sliding, Gradient and Scharr, which falls slightly below the recommended minimal requirement of at least 250 data points.
    Nevertheless, this led to a more extensive distribution of data points, thus yielding improved outcomes with respect to the correlation.

    A comprehensive evaluation of the data indicates that while the outcomes for houses are not directly comparable to those of other houses, they are consistent within their own respective dataset.
    Consequently, all figures display the initially separated results as well as the combined data points in the final line.
    The incorporation of a greater number of data points, amounting to 840, is assumed to provide a more comprehensive representation of the quality of the algorithm to be measured.
    It is imperative to acknowledge that all data points mapping to the origin are excluded from the calculation, as they are considered outliers. 
    These outliers are attributed to executions where the algorithm's inability to accurately identify the house base area resulted in no predicted segments being generated.
    The inclusion of these variables would compromise the integrity of further analysis by distorting the scale of the data and impeding the process of normalisation.

    ==== MAE, MSE, RMSE and R2 Score <section:metrics>
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "MAE" = (1/n) * sum_(i=1)^n |y_i - accent(y, hat)_i| $ <formula:mae>
    $ "MSE" = (1/n) * sum_(i=1)^n (y_i - accent(y, hat)_i)^2 $ <formula:mse>
    $ "RMSE" = sqrt("MSE") $ <formula:rmse>
    $ R^2 = 1 - (sum_(i=1)^n (y_i - accent(y, hat)_i)^2)/(sum_(i=1)^n (y_i - accent(y, macron))^2) $ <formula:r2>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    One approach entailed the utilisation of conventional statistical metrics for the assessment of the discrepancy between two datasets.
    Specifically, the following metrics are of relevance: the #abr("MAE"), the #abr("MSE"), the #abr("RMSE"), and the R2 score.
    
    The #abr("MAE") and #abr("MSE") are calculated by taking the absolute or squared difference respectively between the two datasets and averaging it, as demonstrated in @formula:mae and @formula:mse. 
    The #abr("RMSE") is calculated by simply taking the square root of the #abr("MSE"), shown in @formula:rmse.
    More complex, the R2 score is calculated by taking the variance of the two datasets and dividing it by the variance of the first dataset, as demonstrated in @formula:r2.

    The #abr("MAE"), #abr("MSE"), and the #abr("RMSE") are all error metrics. 
    These metrics directly measure the differences between the values of two datasets, under the assumption that the two datasets are directly correlated 1-to-1.
    The R2 score is a measure of the extent to which the data aligns with a linear model, also referred to as the coefficient of determination.
    This range extends from $(-infinity, 1]$, with 1 representing a perfect fit and negative values denoting a lack of fit for the data within the linear model.

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
    The results from the #abr("MAE") and #abr("RMSE") are highly congruent in this instance.
    This phenomenon can be attributed to the inherent limitations of the data, which is constrained within the range of 0 to 1. 
    Consequently, the utilisation of the #abr("MAE") as a standalone metric is sufficient for data analysis in this context, as the impact of the #abr("RMSE") on outliers is deemed negligible.

    The R2 score's open range of $(-infinity, 1]$ complicates analysis.
    Interpreting the R2 score poses a significant challenge, as it would necessitate the creation of a valid interpretation of the relationship between the score's magnitude and the performance of the algorithm.
    An evaluation indicates that the values predominantly manifest a negative tendency, with most instances exhibiting lower magnitudes. 
    However, it is noteworthy that some instances display significantly higher magnitudes.
    This observation strongly suggests that the algorithmic correlation does not align much with the suppositions made in this particular section.
    However, the fundamental principle of the R2 score and the assessment of the congruence between the data and a linear model remains an essential property of the algorithm, a consideration that will be pertinent to the subsequent steps.
    
    The R2 score demonstrated by @fig:truth_compare:metrics:a is notably negative, suggesting a complete absence of correlation between the algorithm and the ground truth data.
    However, an examination of the data suggests an alternative conclusion, indicating a linear relationship that is simply tilted, rather than originating from the origin (0, 0), as the R2 score implemented here assumes.


    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../data/6/10/v1/correlation/metrics.png"), caption: [
        Example A.
      ]), <fig:truth_compare:metrics:a>,
      figure(image("../data/6/18/v1/correlation/metrics.png"), caption: [
        Example B.
      ]), <fig:truth_compare:metrics:b>,
      figure(image("../data/6/16/v1/correlation/metrics.png"), caption: [
        Example C.
      ]), <fig:truth_compare:metrics:c>,
      caption: [
        Example results for using #abr("MAE"), #abr("MSE"), #abr("RMSE") and R2 score
      ],
      label: <fig:truth_compare:metrics>,
    )

    @fig:truth_compare:metrics:c reveals a strong correlation with the ground truth data, as evidenced by it's calculated R2 score.
    This observation indicates that the linear relationship between the scores and truth scores is more skewed towards the origin in comparison to the scenario depicted before, but does not generally depict a better linear relationship between the data itself.

    @fig:truth_compare:metrics:b offers yet another perspective.
    The R2 score remains in a negative range, although it is less pronounced than in the first example but more significant than in the second.
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

    ==== Pearson Coefficient <section:pearson>
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "cosine similiarty" = (arrow(x) dot arrow(y)) / (||arrow(x)|| dot ||arrow(y)||) $ <formula:cosine>
    $ "pearson coefficient" = (n * sum(x * y) - sum(x) * sum(y)) / sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2)) $ <formula:pearson>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    An alternative approach to measuring the correlation between two datasets is the Cosine Similarity @Cosine2.
    This approach was conceived as a means to assess the quality of the scoring in terms of direction, given its fundamental purpose being to quantify the similarity between the data point vectors.
    The cosine similarity is calculated by taking the dot product of the two vectors and dividing it by the product of both vectors' magnitudes, as shown in @formula:cosine.

    Nevertheless, said similarity is still derived from the direction of the origin (0, 0).
    This means the algorithm still assummes an identity mapping between the two datasets, a property that, as previously discussed, is not wanted.
    A potential solution to this issue is normalisation of the data, which would result in the data falling within the full range of 0 to 1.

    The calculation of cosine similarity on normalised data is analogous to the calculation of the Pearson coefficient @Pearson4 @Pearson2 @Pearson3.
    The Pearson coefficient is another metric of linear correlation between two datasets.
    It ranges from -1 to 1, with 1 representing a perfect positive correlation and -1 representing a perfect negative correlation.
    The Pearson coefficient is calculated by taking the covariance of two datasets and dividing it by the product of the standard deviations of said datasets. This calculation can be performed using the @formula:pearson function.
    A Pearson coefficient of 1 during experimentation would indicate a perfect correlation between the two datasets.
    In such circumstances, the score derived from the segmentation algorithm and the ground truth data are demonstrably congruent, attributable to a reliable correlation.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    Nevertheless, given that Scipy provides the Pearson function @Pearson1, it is unnecessary to implement this function independently.
    The function accepts two arrays as inputs and produces the Pearson coefficient.
    Note that the method also returns a p-value demonstrating confidence, which however will not be utilised in this context.
    The following example code snippet offers a small abstract of the code.

    ```python
    from scipy.stats import pearsonr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = pearsonr(scores, truth_scores)
    print(f"Pearson: {r:.3f}")
    ```

    #pagebreak()
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

    The discrepancy in the values, with some at 0.6 and others at 0.8, remains to be explained, but it is evident that both values serve as at least adequate indicators for the correlation of scores.
    It is reasonable to hypothesise that this phenomenon is attributable to the scoring system's strong penalisation of undersegmentation segmentations, which scores are completely nullified.
    In contrast, the ground truth data's #abr("IoU") values exhibit only a marginal sensitivity to such inaccuracies.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../data/6/10/v1/correlation/pearson.png"), caption: [
        Example A.
      ]), <fig:truth_compare:pearson:a>,
      figure(image("../data/6/18/v1/correlation/pearson.png"), caption: [
        Example B.
      ]), <fig:truth_compare:pearson:b>,
      figure(image("../data/6/16/v1/correlation/pearson.png"), caption: [
        Example C.
      ]), <fig:truth_compare:pearson:c>,
      caption: [
        Example results for pearson coefficient
      ],
      label: <fig:truth_compare:pearson>,
    )

    ==== Combination of Metrics by using a Linear Regressor

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    The subsequent stage of the research involved the formulation of a linear function, with the objective of calculating the correlation between the two datasets directly.
    The prerequisite for this endeavor entails the calculation of the most optimal linear relationship and the implementation of metrical comparison of the data in alignment with that relationship.

    This objective was accomplished by using the LinearRegression class of the scikit-learn library @LinearRegressor, which facilitated the calculation of a linear regression line between the two datasets and enables the calculation of the R2 score and the #abr("MAE") towards that linear regression line.
    This fulfills the requirement of a non-strict 1-to-1 linear relationship between the two datasets, as well as returns the metrics that indicate the performance of the algorithm.
    In addition, the R2 score this time is effectively constrained to the range of 0 to 1 in this iteration, in contrast to previous iterations. 
    This is due to the fact that, under the most sub-optimal conditions, the algorithm would return 0, meaning the regressor essentially mimics an algorithm which simply takes the mean of the data.
    This represents a marked enhancement over earlier iterations, in which the R2 score was not constrained and could attain unconstrained negative values, leading to challenges in interpretation.

    As previously outlined in @section:metrics, the #abr("MAE") is a reliable metric for assessing the accuracy of the algorithm, while the R2 score is a valuable indicator of the suitability of the data for a linear model.
    The #abr("MAE") is inherently an error metric that should be minimised. 
    It is thus normalised to the range of 0 to 1. 
    This is followed by inversion through subtraction from 1 to create a score that represents a maximisation task.
    This is performed to ensure that the calculated #abr("MAE") score is aligned with the R2 score, thereby ensuring that the resulting score is optimised to 1.
    The resulting correlation score is derived by calculation of the weighted average between the R2 and the #abr("MAE") scores.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The resulting correlation score is then calculated by taking the weighted average of the R2 score and the #abr("MAE"), as illustrated in the following code example.
    The variable mae_norm_score is defined as the inverse of the #abr("MAE"), which subsequently is to be maximised.
    The constrained range of the R2 score is not immediately apparent.
    Nonetheless, the resulting correlation score is effectively constrained to the range of 0 to 1, which is the desired property of the algorithm.
    To ensure simplicity, the alpha value is set to 0.5, thereby assigning equal weight to both metrics.

    ```python
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import mean_absolute_error

    def linear_regression(scores, truth_scores, alpha=0.5):
        # Reshape to match LinearRegression model expected input
        scores_reshaped = np.array(scores).reshape(-1, 1)
        truth_scores_reshaped = np.array(truth_scores).reshape(-1, 1)

        # Create and fit the model
        model = LinearRegression()
        model.fit(scores_reshaped, truth_scores_reshaped)
        # Trend line for later visualisation
        trend = model.predict(scores_reshaped)
        # Calculate R2 score
        r2 = model.score(scores_reshaped, truth_scores_reshaped)
        # Calculate MAE
        mae = mean_absolute_error(truth_scores_reshaped, trend)
        mae_norm = mae / (max(truth_scores) - min(truth_scores) + 1e-10)
        mae_norm_score = 1 - mae_norm # Inverse the normalised MAE

        # Calculate resulting score
        result = (alpha * r2) + ((1 - alpha) * mae_norm_score)
        return result, r2, mae_norm_score, trend

    # Example Usage:
    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    result, r2, mae_score, trend = linear_regression(scores, truth_scores)
    print(f"Correlation Score: {result:.3f}")
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    The results of the new correlation metric applied to the example images are shown in @fig:truth_compare:correlation.
    While the results are encouraging in terms of demonstrating the algorithm's capabilities, they unfortunately do not reveal any significant enhancement in comparison to @section:pearson.
    
    It is evident that all scores are comparable to the Pearson coefficient values. This observation aligns with the underlying principle of the algorithm, which is rooted in measuring the correlation between two datasets. 
    This further substantiates the reliability of the Pearson coefficient values as a reliable metric for assessing the performance of the algorithm.

    The results indicate minimal absolute errors in relation to their respective linear fits.
    An examination of @fig:truth_compare:correlation:a and @fig:truth_compare:correlation:c reveals the algorithm's capacity to generate satisfactory outcomes, as evidenced by the normalised #abr("MAE") and the R2 score.
    However, it is evident that the fits are not perfect, or rather, do not align with expectations. 
    This deviation can be attributed to the presence of clear outliers in the scatter plot.

    A more compelling comparison can be made by examining the example of @fig:truth_compare:correlation:b.
    In this case, the algorithm's scores consistently fall short of the desired level of satisfaction.
    The issue lies in the fact that, while the correlation scores do reflect a lower quality compared to the other two examples, they do not represent this as effectively as desired.
    The phenomenon can be explained by the equitable weighting of the two metrics. 
    The R2 score represents the poor linear correlation well, but the #abr("MAE") score does not. 
    The #abr("MAE") score measures distance from the fit, which itself is not of poor quality; but built upon substandard data.
    Consequently, the MAE score is not a reliable metric for evaluating the linear relationship when compared to the R2 score.
    The resulting score's meaning is not invalidated by this observation, since a lower score is still indicative of a lower quality. 
    However, the degree of decrease is not as pronounced as it should be.

    A more substantial problem that can be observed is evident in the result of this example using the Sobel derivative.
    The R2 score in this case, while still comparatively low, demonstrates indications of improvement in comparison with the other derivatives.
    This however, does not stem from an actual improvement in the data. 
    It is an indicator that the data align more closely with a linear relationship.
    However, this is not a favorable outcome, as the linear relationship exhibits an evident anti-correlation with the ground truth data.
    Conversely, a higher score that does not align with the expected outcome is not consistent with the principle of faithfulness to expectation.
    In @section:pearson, this was previously indicated by a negative correlation score; however, within this approach, there is no longer any indicator for this.

    In view of the aforementioned issues and the inability to enhance the Pearson coefficient, this specific metric is not regarded as a success and will not be utilised in the final evaluation.
    The sole viable enhancement here was a straightforward method to visually depict the linear correlation between the two datasets.
    
    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../data/6/10/v1/correlation/regression.png"), caption: [
        Example A.
      ]), <fig:truth_compare:correlation:a>,
      figure(image("../data/6/18/v1/correlation/regression.png"), caption: [
        Example B.
      ]), <fig:truth_compare:correlation:b>,
      figure(image("../data/6/16/v1/correlation/regression.png"), caption: [
        Example C.
      ]), <fig:truth_compare:correlation:c>,
      caption: [
        Example results for using linear regression
      ],
      label: <fig:truth_compare:correlation>,
    )

    ==== Spearman Coefficient <section:spearman>
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ "Spearman" r_s = 1 - (6 * sum(d_i^2)) / (n * (n^2 - 1)) $ <formula:spearman>
    $d_i$ signifies the difference in ranks between the two datasets and $n$ is the number of overall data points.
    For instance, the sets $[1, 2, 3]$ and $[3, 2, 1]$ would result in $d_i = [2, 0, -2]$ and $n = 3$.

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    The strict requirement of a linear relationship can be relaxed to a monotone relationship between the two datasets. 
    In such instances, the Spearman coefficient can be employed to measure the coefficient of relation @spearman1.
    The Spearman coefficient is a non-parametric measure of rank correlation. 
    It assesses how well the relationship between two variables can be described by a monotonic function.
    This approach is analogous to the Pearson coefficient, as discussed in @section:pearson, with the key distinction being that it does not utilise the raw values directly. 
    Instead, it employs the rank order of the values, as demonstrated in @formula:spearman.
    The range and interpretation of the resulting score function similarly to the Pearson correlation coefficient @spearman2.

    #heading(depth: 5, numbering: none, bookmarked: false)[Code Snippet]
    The implementation of the Spearman coefficient, much alike the implementation of the Pearson coefficient, also utilises the Scipy library implementation @spearman3.

    ```python
    from scipy.stats import spearmanr

    scores = [0.5, 0.6, 0.7, 0.8]
    truth_scores = [0.5, 0.6, 0.7, 0.8]

    r, _ = spearmanr(scores, truth_scores)
    print(f"Spearman: {r:.3f}")
    ```

    #pagebreak()
    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    The findings of this experiment are illustrated in @fig:truth_compare:spearman and appear to be promising.
    As demonstrated by the Spearman coefficient, @fig:truth_compare:spearman:a and @fig:truth_compare:spearman:c exhibit a high or very high positive correlation with the ground truth data.
    The results of @fig:truth_compare:spearman:b are not as favorable, rather indicating no or a very weak correlation.

    The Spearman rank correlation coefficient is a valuable non-parametric measure of monotonic relationships between two variables. 
    However, it has been observed to be misleading when the data points are densely clustered within a narrow value range.
    The scores are typically confined to the interval $[0, 1]$, though in practice, most values may be concentrated within a small subinterval.

    In circumstances where such clustering occurs, rank distinctions become minimal or ambiguous, thereby reducing the meaningful variability that Spearman relies on to detect correlation.
    This is essentially what transpired in @fig:truth_compare:spearman:b, particularly when comparing solely the values generated using Scharr.
    Consequently, even in the presence of a genuine underlying trend, the coefficient may exhibit a low or unstable correlation. 
    This is attributable to the fact that the input lacks sufficient spread to clearly express monotonic relationships.
    This effect is especially pronounced when absolute differences in segmentation quality are subtle and fail to translate into distinct ranks.

    Therefore, it is imperative to exercise caution when interpreting Spearman coefficients in such circumstances.
    A comparative analysis of the data reveals that it is generally comparable to the results obtained from the Pearson coefficient.
    A thorough examination of the data reveals no substantial disparities between the two methods, at least based on the examples that have been presented.
    Consequently, the final evaluation will be conducted using both the Spearman and the Pearson coefficients. 
    These are two valid metrics for measuring the correlation between two datasets, and therefore both may be used to provide valuable insights.

    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../data/6/10/v1/correlation/spearman.png"), caption: [
        Example A.
      ]), <fig:truth_compare:spearman:a>,
      figure(image("../data/6/18/v1/correlation/spearman.png"), caption: [
        Example B.
      ]), <fig:truth_compare:spearman:b>,
      figure(image("../data/6/16/v1/correlation/spearman.png"), caption: [
        Example C.
      ]), <fig:truth_compare:spearman:c>,
      caption: [
        Example results for spearman correlation
      ],
      label: <fig:truth_compare:spearman>,
    )

    === Overall Assessment
    As previously stated, this section will employ the Pearson and Spearman coefficients to analyse the provided data.
    The scope of this initiative will expand beyond the initial three examples provided by @fig:truth_compare:examples, encompassing all twenty examples that include ground truth segmentations.
    While neither coefficient necessitates normalisation in theory, for enhanced comparability between different entries, they are nevertheless normalised.
    This also renders the data more visually comprehensible and facilitates the consolidation of the datasets into a single entity, as otherwise, the consolidation of the rankings would be unfeasible.
    This means that the absolute values of each individual dataset are lost, which will lead to complications in the subsequent analyses.
    Contrary to the preceding sections, the present section does not entail the evaluation of the method of metric calculation. 
    Rather, the emphasis has shifted to the examination of the actual results and the entry data which gave rise to outlier.

    #heading(depth: 5, numbering: none, bookmarked: false)[Individual Entries]
    As demonstrated by @fig:truth_compare:final, the aggregate data for all derivatives, subsequent to being normalised, is confined within the full spectrum of $[0, 1]$.
    The majority of the results obtained lend substantial support to the assumption of up to very high correlation.
    As previously mentioned, each cell encompasses the aggregate of 840 data points, thereby meeting the requisite minimum of 250 points to ensure the attainment of stable results.
    The following observations can be made:

    Firstly, three data sets did not optimally normalise the data due to the presence of one or more outliers, which resulted in the distortion of the data's maximum and minimum values.
    The correlation scores of these data sets are satisfactory, irrespective of the metrics employed, as they are not dependent on the normalisation process.
    However, this approach may present certain challenges when attempting to evaluate all datasets collectively. 
    Specifically, the inclusion of these datasets can result in a reduction of the overall score, as they contribute "worse" points to the graph within the overarching context.
    The relevance of the MAE in this particular instance could be a subject of debate, as it functions as an indicator of the quality of the data subsequent to normalisation, since this effectively addresses the issues encountered in @section:metrics.

    #figure(
      image("../figures/truth_compare/final_results/all_data.png"), 
      caption: [
        Normalised point clouds with pearson and spearman coefficients
      ],
    )<fig:truth_compare:final>

    Two datasets demonstrate only a relatively minor correlation, while one exhibits no correlation.
    Nevertheless, this can be traced back to the effects of normalisation, which distorts the perception of the data visually. 
    Initially, all data points were closely grouped, which led to this observation.
    Despite the inability to identify a more precise solution to this problem, an examination of the segmentations themselves suggests that they are not of bad quality.

    Two datasets exhibits a comparatively low Spearman coefficient value, yet concurrently demonstrating a high Pearson coefficient value.
    The majority of the data points are concentrated in the top-right quadrant, in close proximity to each other, thereby creating a distinctive pattern.
    Consequently, they exhibit a satisfactory linear correlation, as evidenced by the Pearson outputs and substantiated by visual confirmation.
    However, due to the proximity of most points, the rank of the points becomes distorted.
    This issue is not of significant concern, as we consider values of comparable magnitude to be interchangeable. 
    However, it should be noted that the Spearman coefficient does not take magnitudes into account and consequently yields a low score, which is not alarming.
    This study demonstrates the efficacy of employing both metrics for confirmation, as both metrics yield unexpected results when applied to specific cases, taking into account the particular data quality. 
    This finding suggests that relying on a single metric may not always be sufficient, or maybe even that the Pearson coefficient alone could be sufficient.

    #heading(depth: 5, numbering: none, bookmarked: false)[Combination of All Entries]

    #figure(
      image("../figures/truth_compare/final_results/combined_all_data.png"), 
      caption: [
        Graph of the merged, normalised data points
      ],
    )<fig:truth_compare:final_all>

    Given that all individual sets have undergone normalisation, @fig:truth_compare:final_all shows them after they have been combined into a single, comprehensive dataset for the calculation of metrics.
    Due to the fact that the scatter plot currently displays $20 * 840 = 16800$ data points, its visual appeal has been diminished in comparison to previous iterations.
    The majority of points are situated along the Identity Axis.
    It is evident that there are specific points in the top-left and bottom-right corners of the graph that correspond to the sections of the graph that are considered unfavorable.
    The upper left corner of the matrix displays points that exhibited low algorithm scores but demonstrated satisfactory values when compared with ground truths. This observation is not problematic.
    In general, all points with a score lower than the truth score are of no concern, since this could be due to already acknowledged restrictions like harsher punishment for misclassifications.

    A matter of concern arises in instances where the score significantly exceeds the truth score.
    While minor discrepancies may be disregarded, instances where a minimal truth score is accompanied by an elevated algorithm score in the bottom-right corner pose significant challenges.
    It is fortunate that the specified area is not densely populated. While some points are in close proximity to it, they are not excessively proximate. It is hoped that the number of points is sufficiently limited to ensure that the algorithm remains valid.
    The population of this corner is predominantly attributable to the previously delineated unfortunate normalisation of individual data sets due to outliers.

    Given that this is normalised data, discrepancies between scores and truth scores that are initially smaller appear to be more problematic than in most cases.
    The issue could only be resolved by ensuring that all original data sets contained a wider range of data points for comparison. 
    However, the algorithm currently outputs a limited number of segmentations which are of low quality, making it difficult to achieve this objective. 
    Changing the algorithm to do so would be nonsensical.
    
    The Pearson and Spearman scores demonstrate a high degree of correlation between the data, with values of $0.695$ and $0.666$, respectively.
    The findings indicate that the hypothesis is valid in general, as the scoring system appears to accurately reflect or represent the true score in relation to a ground truth.
    The utilisation of this system on unseen data results in scores that can be relied upon for subsequent analysis.
    Hence, further refinement of normalisation techniques or the removal of outliers is deemed unnecessary. 
    Repeated testing with these modifications would merely constitute a futile expenditure of additional time resources, as the already satisfactory score would only rise.
  ]
}