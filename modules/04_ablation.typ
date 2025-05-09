#import "@preview/subpar:0.2.0"

#let ablation() = {
  text(lang:"en")[
    == Ablation Study and Algorithm Improvement <section:ablation>
    This section describes the ablation study performed to evaluate the impact of different hyperparameters on the performance of the proposed algorithm.
    The study was conducted to identify the optimal values for the hyperparameters and to understand how they affect the algorithm.
    Filtering the hyperparameters to include fewer values to be computed will greatly improve the time efficiency of the algorithm.
    While time efficiency is not a major concern in this study, it is considered here in the context of not sacrificing quality of results for it.
    The original proposed values for each parameter were very broad and probably harshly overestimated which values are reasonable to measure.

    @fig:ablation:time shows the average time per execution.
    Remember that we currently calculate $4 * 10 * 7 * 3 = 840$ executions per image before extracting the best result.
    This means that even the calculated median time of 1.49 seconds results in 20.86 minutes of execution time.
    This is of course unacceptable for a real-time application, and even for other purposes generally too much, especially considering that there are more than 1000 input images in the entire filtered set of houses.

    #figure(
      image("../figures/ablation/time.png"), 
      caption: [
        Bar plot over execution times
      ],
    ) <fig:ablation:time>

    === Blurring Method
    As mentioned, the blurring method is used to smooth the image and reduce noise.
    The choice of blurring method has a significant impact on the quality of the resulting segmentations.
    Therefore, this subsection compares and analyzes the performance of different blurring methods.

    @fig:ablation:blurring shows the extracted blurring methods from each of the calculated best results for each house.
    It is quite obvious that blurring with a 5x5 kernel gives the best overall results.
    However, since there was a case where no blurring performed best, this outlier is worth looking at.
    In all three examples where a 3x3 kernel was used for the best result, the 5x5 kernel showed very little effect on the score and almost no visual effect when comparing the results.
    This indicates that the smaller kernel does not need to be considered further.

    #figure(
      image("../figures/ablation/blurring.png"), 
      caption: [
        Statistics over blurring methods
      ],
    ) <fig:ablation:blurring>

    The results of the only house where blurring is not optimal are shown in @fig:ablation:blurring_none.
    The loss of quality, at least numerically, seems to be quite obvious.
    Note that this is the only house in the test data that consists of flat roof surfaces.
    The negative effect of blurring is most likely due to the fact that flat roof surfaces are less likely to have noise inside them, since the non-changing height is less susceptible to calculation inaccuracies.
    While the score heatmap shows the change to be quite drastic, looking at the truth scores and the resulting segmentations show the change to be less drastic.
    The best truth scores are $0.751$, $0.737$, and $0.740$, which by far do not represent this trend of decreasing quality.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      box(figure(image("../data/6/17/v1/heatmap_none.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/17/v1/heatmap_none.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      box(figure(image("../data/6/17/v1/heatmap.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/17/v1/heatmap.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      box(figure(image("../data/6/17/v1/heatmap_medium.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/17/v1/heatmap_medium.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      caption: [
        Heatmap extracts where not blurring appears optimal
      ],
      label: <fig:ablation:blurring_none>,
    )

    The general effect of blurring is very positive.
    @fig:ablation:blurring_example shows an extracted heatmap that shows the effect of applying different blurring methods.
    Theoretically, blurring the image would lead to a loss of information and thus reduce the effectiveness of the algorithms in detecting thin roof parts.
    However, blurring seems to have the opposite effect on thin roof detection, as can be seen by the green area on the left, which is missing a part when not blurred.
    This is due to the fact that noise on thin parts is more likely to be detected as an edge, which in turn splits the surface.
    The surface in question is still split because the lower right part is only connected by two small edges that are barely visible in the height data.
    This problem cannot be solved here further.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      box(figure(image("../data/6/1/v1/heatmap_none.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/1/v1/heatmap_none.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      box(figure(image("../data/6/1/v1/heatmap.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/1/v1/heatmap.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      box(figure(image("../data/6/1/v1/heatmap_medium.png")), clip: true, width: 110%, inset: (bottom: -2.1in, top: -4.15in, right: -10.45in)),
      box(figure(image("../data/6/1/v1/heatmap_medium.png")), clip: true, width: 80%, inset: (bottom: -2.7in, top: -4.75in, left: -4.9in, right: -8.5in)),
      caption: [
        Example Impact of using different blurring methods
      ],
      label: <fig:ablation:blurring_example>,
    )

    @fig:ablation:blurring_statistic shows sample derivatives for x and y for a selected column and row within one of the examples to demonstrate the effect of blurring.
    It shows quite well how the blurring affects the flicker values, smoothing them out.
    This is effectively the number equivalent to the visual effect discussed earlier, since without blurring the magnitudes of the jumps in the derivative value are much larger and therefore much more likely to incorrectly be detected as an edge.

    #figure(
      image("../figures/ablation/blurring_example.png"), 
      caption: [
        Impact of blurring on an example row and column
      ],
    ) <fig:ablation:blurring_statistic>

    === Derivative Method <section:ablation:derivative>
    The use of each derivative method is evaluated in the same way as the blur method.
    Therefore, @fig:ablation:derivative shows for each method how often it was used to achieve the best result.
    While the results are not quite as clear as for the blur method, it is quite obvious that using the gradient method is the best choice.
    The Custom Sliding Window method actually performs quite well as well.
    One would expect it to perform at least somewhat similarly, remembering that it is a simplification of the novel approach that calculates the gradient.
    Surprisingly, the Sobel and Scharr methods perform quite poorly.
    Again, since they are quite similar approaches, similar performance was to be expected.

    In order to minimise the computational demands associated with determining the optimal parametrization for each individual building, the Scharr and Sliding methods are filtered out.
    The Sobel and gradient methods are retained due to their capacity to yield distinct outcomes, thus rendering both potentially advantageous.
    Furthermore, it should be noted that the aforementioned pair of methods are capable of substituting the removed methods, given their notable similarity.
    This approach results in a reduction of the number of necessary calculations by 50%, while ensuring the maintenance of the overall quality of the results and only minor losses in quality.

    #figure(
      image("../figures/ablation/derivative.png"), 
      caption: [
        Statistics over derivative methods
      ],
    ) <fig:ablation:derivative>

    === Using SAM for Base Area Detection <section:replace_clipping_by_sam>
    As was hypothesised in the preliminary study on the potential applications of the various input images, it was theorised that SAM could be utilised for base area detection.
    In this instance, the hypothesis will be proven true and included in the algorithm.
    Subsequent to the aforementioned change, the algorithm will no longer be dependent on the clipping percentage.

    As demonstrated by @fig:ablation:base_area, the results of the SAM segmentation for three different houses are presented.
    It is notable that the input prompts continue to originate from the mask of the original input data, as its replacement as a data source is not deemed necessary in this instance.
    Furthermore, the substandard quality of the mask has a negligible impact on the quality of the results.

    The bottom example in the figure demonstrates a scenario in which the SAM segmentation fails to detect the entirety of the base area of the building.
    This issue is resolved through the implementation of a straightforward merging process of the detected base area with the mask utilised for its creation.
    The mask's inability to define the base area is problematic; however, in this instance, it is sufficient to substitute for the absent elements in the segmentation.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../data/6/1/sam/sam_mask.png")),
      figure(image("../data/6/19/sam/sam_mask.png")),
      figure(image("../data/6/3/sam/sam_mask.png")),
      caption: [
        Base Area Detection using SAM
      ],
      label: <fig:ablation:base_area>,
    )

    The ensuing two subsections will examine the two parameters that will be impacted by the adoption of this approach to base area detection: the clipping values and the canny values.
    This is due to the fact that the requirement for sufficient clipping to detect the house edges has been rendered obsolete.
    Consequently, it is now feasible to implement segmentations without the need for clipping, a capability that was previously unattainable.
    It is evident that the canny values are also impacted by this change, given their role in detecting the edges of the house. These values are contingent on clipping, which in turn affects the contrast of the value distribution.
    In order to facilitate a more robust comparison, the ensuing results will differentiate between version 1 and version 2 of the algorithm.

    === Clipping Values <section:ablation:clipping>
    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      figure(image("../data/6/clipping_percentage_counts.png"), caption: [
        v1
      ]), <fig:ablation:clipping:a>,
      figure(image("../data/6/v2/clipping_percentage_counts.png"), caption: [
        v2
      ]), <fig:ablation:clipping:b>,
      caption: [
        Statistics over clipping percentages
      ],
      show-sub-caption: (num, it) => {
        [#it.body]
      },
      label: <fig:ablation:clipping>,
    )

    === Canny Values
    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      figure(image("../data/6/canny_value_counts.png"), caption: [
        v1
      ]), <fig:ablation:canny:a>,
      figure(image("../data/6/v2/canny_value_counts.png"), caption: [
        v2
      ]), <fig:ablation:canny:b>,
      show-sub-caption: (num, it) => {
        [#it.body]
      },
      caption: [
        Statistics over canny values
      ],
      label: <fig:ablation:canny>,
    )
  ]
}