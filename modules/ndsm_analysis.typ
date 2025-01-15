#let ndsm_analysis() = {
  text(lang:"en")[
    === NDSM Analysis
    Using the Logarithm on the original, but normalized, NDSM Image data will help to enhance the contrast of the image. This will not only make the image more visually appealing but also easier to interpret. 
    The following image shows the differences when applying the Logarithm.
    We can observe that the image which contains logarithmic normalization has less extreme maxima and minima, which makes it easier to interpret the image, due to the smaller values being more prominent, leading to a more balanced image in intensity.
    In the Image without logarithmic scaling applied, most colours become very pale whilest only the extreme values on for example the edges of the house become intensively coloured, leading to the fact, that the image becomes hard to interpret by human eyes whe ntrying to evaulate or validate the calculated data.
    The results of both are of quite different quality, which is due to the parameter of 'clipped percentage’ and input parameter for the Canny Edge Detection algorithm. 
    It appears that they could be changed in such a way that both images are much more similar in quality, but this is not researched in depth, as the benefit of this is uncertain.
    Most probably investing time into this would not be worth, as the results do not appear to bring groundbreaking quality improvements.
    Further experiments will continue to use the logarithmic normalization, as it is a simple and effective way to enhance the contrast of the image, which in turn results in a wider or better scope for parameter tuning.

    #figure(
      image("../figures/apply_log/Result_Log_V3.png", width: 100%),
      caption: [
        Comparison between using the Logarithm on the original, but normalized, NDSM Image data and the original NDSM Image data without prior adjustments.
      ],
    )
    === Canny Edge Detection

    === Surface Growth

    #figure(
      image("../figures/surfaces/surfaces_pipeline.png", width: 100%),
      caption: [
        The result of each step inside the surface pipeline. The parameter used here are 50% minimum overlap for the Best Surfaces as well as the Filtered Surfaces.
      ],
    )

  ]

  pagebreak()
}