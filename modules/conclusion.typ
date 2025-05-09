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

    The sequence of algorithmic steps is contingent on the specific hyperparameter settings, which, in turn, are determined by the characteristics inherent in each building's data.
    The development of an automated pipeline was undertaken in order to ascertain the optimal set of parameters for the feature extraction methods.
    The quality assessment of the generated segmentations was conducted through the utilisation of newly devised evaluation metrics.
    In order to evaluate the correctness of a given predicted segmentation, the pipeline performs a series of calculations based on geometric characteristics.
    This methodology enabled the comparison of the outcomes derived from various parameter iterations, thereby facilitating the selection of the most appropriate iteration.
    The reliability of these evaluation metrics was established through a comparison with the ground truth.







    The performance of SAM was evaluated by comparing its results when guided by geometric prompts generated through the proposed pipeline with those obtained using less informed or manual prompting strategies. 
    The evaluation was conducted by applying the input prompts using different input prompt generation strategies as well as different input images.

    The 
    The results were compared against other segmentation approaches, including SAM with random or no prompts, and manual prompting strategies. 
    The evaluation highlighted that SAM, when guided by the geometric prompts generated through this methodology, achieved higher segmentation accuracy and better preservation of geometric features in comparison to less informed or manual methods. 
    This demonstrated the effectiveness and potential of geometric prompts in fine-grained roof segmentation tasks.


    // -> more extensive research on the configurations of sam input prompts especially negative ones
    // -> more educated approach of combining the different sam input prompts
  ]
}