#import "@preview/subpar:0.2.0"

#let ablation() = {
  text(lang:"en")[
    == Ablation Study and Algorithm Improvement
    This section describes the ablation study performed to evaluate the impact of different hyperparameters on the performance of the proposed algorithm.
    The study was conducted to identify the optimal values for the hyperparameters and to understand how they affect the algorithm.
    Filtering the hyperparameters to include fewer values to be computed will greatly improve the time efficiency of the algorithm.
    While time efficiency is not a major concern in this study, it is considered here in the context of not sacrificing quality of results for it.
    The original proposed values for each parameter were very broad and probably harshly overestimated which values are sensical to measure.

    @fig:ablation:time shows the average time per execution.
    Remember that we currently calculate $4 * 10 * 7 * 3 = 840$ executions per image before extracting the best result.
    This means that even the calculated median time of 1.49 seconds results in 20.86 minutes of execution time.
    This is of course unacceptable for a real-time application, and even for other purposes generally too much, especially considering that there are more than 1000 input images in the entire filtered set of houses.

    #figure(
      image("../figures/ablation/time.png"), 
      caption: [Bar plot over Execution Times],
    ) <fig:ablation:time>

    === Impact of Hyperparameter Values

    ==== Blurring Method
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
      caption: [Analysis of Best results for different blurring methods],
    ) <fig:ablation:blurring>

    The results of the only house where blurring is not optimal are shown in @fig:ablation:blurring_none.
    The loss of quality, at least numerically, seems to be quite obvious.
    Note that this is the only house in the test data that consists of flat roof surfaces.
    The negative effect of blurring is most likely due to the fact that flat roof surfaces are less likely to have noise inside them, since the non-changing height is less susceptible to calculation inaccuracies.
    While the score heatmap shows the change to be quite drastic, looking at the truth scores and the resulting segmentations shows the change to be less drastic.
    The best truth scores are $0.751, $0.737, and $0.740$, which by far do not represent this trend of decreasing quality.

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
        Extract from the Heatmaps on the only house where not blurring is optimal.
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
        Example Impact of using different blurring methods.
      ],
      label: <fig:ablation:blurring_example>,
    )

    @fig:ablation:blurring_statistic shows sample derivatives for x and y for a selected column and row within one of the examples to demonstrate the effect of blurring.
    It shows quite well how the blurring affects the flicker values, smoothing them out.
    This is effectively the number equivalent to the visual effect discussed earlier, since without blurring the magnitudes of the jumps in the derivative value are much larger and therefore much more likely to incorrectly be detected as an edge.

    #figure(
      image("../figures/ablation/blurring_example.png"), 
      caption: [Impact of Blurring on an example row and column.],
    ) <fig:ablation:blurring_statistic>



    ==== Derivative Method
    The use of each derivative method is evaluated in the same way as the blur method.
    Therefore, @fig:ablation:derivative shows for each method how often it was used to achieve the best result.
    While the results are not quite as clear as for the blur method, it is quite obvious that using the gradient method is the best choice.
    The Custom Sliding Window method actually performs quite well as well.
    One would expect it to perform at least somewhat similarly, remembering that it is a simplification of the novel approach that calculates the gradient.
    Surprisingly, the Sobel and Scharr methods perform quite poorly.
    Again, since they are quite similar approaches, similar performance was to be expected.

    #figure(
      image("../figures/ablation/derivative.png"), 
      caption: [Analysis of Best results for different derivative methods],
    ) <fig:ablation:derivative>

    // TODO

    ==== Clipping Values
    
    ==== Canny Values

    === Using SAM for Base Area Detection <section:replace_clipping_by_sam>
  ]
}