#import "@preview/subpar:0.2.0"

#let conclusion() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Conclusion and Future Work
    In the context of this research, an exploration of computer vision techniques was conducted for the purpose of extracting geometric features.
    A series of key techniques were subjected to detailed evaluation in order to ascertain their suitability for identifying fine-grained structural roof features, with a view to facilitating precise segmentation.
    The techniques employed in this study encompassed edge detection, segmentation, and morphological operations.
    A range of methodologies were subjected to rigorous testing in order to ascertain their effectiveness in extracting significant geometric features from the nDSM data.
    The gradient method for calculating derivatives has been demonstrated to be a reliable technique for analysing data to detect precise edges in the nDSM data.
    Empirical evidence has demonstrated the effectiveness of techniques such as logarthmic scaling, clipping of extreme values, and blurring in reducing noise and enhancing relevant features.

    The sequence of algorithmic steps for is contingent on the specific hyperparameter settings, which, in turn, are determined by the characteristics inherent in each building's data.
    The development of an automated pipeline was undertaken in order to ascertain the optimal set of parameters for the feature extraction methods.
    The quality assessment of the generated segmentations was conducted through the utilisation of newly devised evaluation metrics.
    In order to evaluate the correctness of a given predicted segmentation, the pipeline performs a series of calculations based on geometric characteristics.
    This methodology enabled the comparison of the outcomes derived from various parameter iterations, thereby facilitating the selection of the most appropriate iteration.
    The reliability of these evaluation metrics was established through a comparison with the ground truth.

    The performance of SAM was evaluated by comparing its results when guided by geometric prompts generated through the proposed pipeline with those obtained using less informed or manual prompting strategies.
    The utilisation of prompts guided by reliable geometric features has been demonstrated to yield superior outcomes in comparison to random or manual prompts. This is attributable to the fact that such prompts offer a more informed basis for the segmentation process.
    The evaluation process involved the implementation of various input prompt generation strategies and the utilisation of diverse input images.
    The optimal prompting method remains indeterminate, as the performance of SAM exhibited a high degree of variability, contingent on the characteristics of the input image and the specific properties of the prompted segment.
    Following a thorough evaluation, it was determined that none of the experimental images were capable of fully capturing the required level of information.
    In different situations, different images were found to outperform others, with no clear objective winner identified.
    The reliability scores of SAM were considered to be an unreliable indicator of mask quality, as the confidence by SAM does not always reflect the actual quality of the segmentation.
    A promising approach was to combine the results of different prompting methods, as this approach yielded the best results in most cases.
    However, a more sophisticated approach to combining these factors is to be evaluated in future research.




    // -> more extensive research on the configurations of sam input prompts especially negative ones
    // -> more educated approach of combining the different sam input prompts
  ]
}