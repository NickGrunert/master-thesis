#import "@preview/subpar:0.2.0"

#let sam(abr) = {
  text(lang:"en")[
    = Using SAM for zero-shot segmentation
    In this chapter, we will initiate the experimental phase concerning the usability of #abr("SAM") in the context of roof segmentation.
    The objective is to ascertain the necessary input data to facilitate effective segmentations and to determine the optimal utilisation of #abr("SAM") to achieve this objective.

    == Images <section:sam:images>
    This section will shortly list the types of images that will be used in the evaluation.
    While other concepts were briefly explored, none of these approaches represented novel methodologies and were met with very limited success.
    The objective of this section is to identify promising candidates of images, data, or preprocessing steps that have the potential to serve as input data for the #abr("SAM") model to subsequently generate segmentations displaying the roof shape.

    #heading(depth: 5, numbering: none, bookmarked: false)[RGB Image]
    One of the images that can be used is the original #abr("RGB") image itself.
    However, it should be noted that the utilisation of #abr("RGB")  data does not provide additional height information and presents certain challenges.

    For instance, the presence of shadows within the data can result in severe misclassifications, as the model may lack the capacity to differentiate between the shadow and the object.
    It has been observed that, due to geometric constraints, the majority of surfaces are either wholly shaded or wholly illuminated; however, this is not guaranteed.
    The presence of shadows can result in strongly divergent values across all colour channels. 
    This phenomenon hinders the effectiveness of an algorithm in identifying similarities between segments that are not shaded and those that are shaded.

    Shadows are a prominent feature of the input data, attributable to the geographical location of Germany, which results in a sun position that casts shadows on a significant proportion of residential structures.
    In order to enhance the utilisation of the raw #abr("RGB") data, an algorithm for shadow removal is implemented. 
    This algorithm utilises Gaussian kernels to identify and eliminate shadowed regions @shadows1 @shadows2 @shadows3.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../data/6/19/image.png", width: 50%)),
      figure(image("../data/6/19/sam/shadow_removed_image.png", width: 50%)),
      caption: [
        Comparison between image and shadow removed image
      ],
      label: <fig:sam:shadows>,
    )

    As demonstrated by @fig:sam:shadows, a clear distinction emerges between the original image and the shadow removed image.
    It is evident that the algorithm has a profound effect on the overall colouration of the image.
    This modification may be advantageous in that it prevents the algorithm from being distracted by colour changes across a coherent surface.
    The presence of discernible boundaries within the colour channels is indicative of a failure to effectively differentiate between surfaces.
    This finding merits further consideration in subsequent experiments. 
    The objective of these experiments is to ascertain whether the shadow removal algorithm can enhance the segmentation results of the #abr("SAM") model.

    #heading(depth: 5, numbering: none, bookmarked: false)[nDSM Image]
    Due to the fact that the #abr("RGB") data contains a substantial amount of information that is either not beneficial or even detrimental when provided to #abr("SAM"), we will try to enhance the input data by using the #abr("nDSM") data, which contains the height information of the current image frame.
    The incorporation of this data is expected to result in enhanced quality, as it is considered to be valuable information regarding the surface structure.

    #subpar.grid(
      columns: 5,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/sam_mask.png")), clip: true, width: 100%, inset: (right: -2.9in)),
      caption: [
        nDSM image with value distribution
      ],
      label: <fig:sam:images:ndsm>,
    )

    However, the utilisation of #abr("nDSM") data as #abr("SAM") input appears to be not possible in a direct manner.
    This hypothesis is the result of a thorough analysis of @fig:sam:images:ndsm.
    This phenomenon is evidenced by the minimal contrast present in the image, indicative of its limited information content.
    However, the value graph distinctly demonstrates the potential for differentiating between the roof and the ground.
    As this topic has not been the primary focus of the present discussion, further examination of it will be reserved for a later in @section:replace_clipping_by_sam.

    #heading(depth: 5, numbering: none, bookmarked: false)[Custom Derivative Image]
    Since the #abr("nDSM") data cannot be used directly, the aim here is to create a custom image that visually represents the derivative, so that it can be used as input for #abr("SAM").
    #abr("SAM") originally tries to find good matching segments across the given red, green and blue channels.
    The task is to find a good mapping from the original derivative data to the red, green and blue channels.

    This was done by calculating the magnitude of the x and y directions.
    However, as we do not want to lose the precise information as to whether x and/or y were positive or negative, the colour is mapped to the four quadrants.
    However, because there are only three colour channels, one of the quadrants is mapped to yellow, which is a combination of red and green.
    This may be slightly sub-optimal, as it means that values within quadrant IV are closer to values in quadrants I and II than to values in quadrant III, since the third quadrant only contains values within the blue channel, while the other quadrants are mapped to red and green.

    Note that this implementation originally contained the bug of incorrectly normalising the colour values.
    Since the square root of the sum of squares was used to calculate the magnitude, the magnitude value could originally be greater than 255, which in turn meant that all values above this threshold were clipped to 255.
    It was found that this had very little effect on the algorithms, but was later fixed by dividing by the maximum value of the magnitude.

    ```python
    def create_3d_derivative_image(...):
      def get_colour(x, y, max_magnitude):
        magnitude = np.sqrt(x**2 + y**2)
        magnitude = magnitude / max_magnitude if max_magnitude > 0 else 0

        if x >= 0 and y >= 0:
          return (magnitude, 0, 0)          # Red for Quadrant I
        elif x < 0 and y >= 0:
          return (0, magnitude, 0)          # Green for Quadrant II
        elif x < 0 and y < 0:
          return (0, 0, magnitude)          # Blue for Quadrant III
        else:
          return (magnitude, magnitude, 0)  # Yellow for Quadrant IV

      # ... Create derivatives x and y

      image = np.zeros((height, width, 3), dtype=np.float32)
      max_magnitude = np.max(np.sqrt(derivative_x**2 + derivative_y**2))
      for r in range(height):
          for c in range(width):
              image[r, c] = get_scaled_colour(x[r, c], y[r, c], max_magnitude)
      image = (image * 255).astype(np.uint8)

      return image
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Color Channel Swaps]
    The original #abr("RGB")  data is rendered incomplete due to an absence of height information, and the derived image may itself be compromised by inaccuracies in the height data.
    It can be argued that certain segments may be more effectively represented visually by the original #abr("RGB")  values.
    For instance, two segments with analogous derivatives that are adjacent to each other yet situated at different heights may prove challenging to discern through the utilisation of solely the derived image.
    In the context of #abr("RGB")  data, however, such transitions are frequently pronounced due to the presence of shadows or other chromatic variations.

    In order to identify a solution that involves the merging of the colour channel information with the spatial data of the derivative image, it is proposed that the colour channels of the original #abr("RGB")  data be swapped with the derivative's magnitude.
    It should be noted that preliminary experiments were conducted in which two colour channels were substituted for the derivatives in the x and y directions.
    Initial testing demonstrated an inability to convey any useful information to #abr("SAM").
    Furthermore, a similar outcome was observed in images of a greyscale.

    However, utilising the full range of methodologies available for combining the derivative image and the original three channels of the #abr("RGB")  data, it is possible to create three distinct images.
    It is hypothesised that each of these will hold some spatial information as well as colour information, which may be promising in augmenting the input data for #abr("SAM").

    #heading(depth: 5, numbering: none, bookmarked: false)[Synopsis]
    As demonstrated in the @fig:sam:images, a selection of images for each house has been selected for use in the evaluation.
    The initial hypothesis is that the #abr("RGB")  image and the #abr("RGB")  image with shadow removal will yield similar results, with the original image performing slightly worse.
    It is hypothesised that the derivative image will demonstrate the strongest overall performance, given its possession of the most valuable height information.
    The quality of the images, in which the colour channels are substituted for derivative information, is yet to be determined through experimental investigation.
    The current hypothesis is that none of the three images will always perform optimally, but that there will be situations where individuals from these three will not be usable, while the others yield satisfactory results.

    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../data/6/1/helper/image_0.png")),
      figure(image("../data/6/1/helper/image_1.png")),
      figure(image("../data/6/1/helper/image_2.png")),
      figure(image("../data/6/1/helper/image_3.png")),
      figure(image("../data/6/1/helper/image_4.png")),
      figure(image("../data/6/1/helper/image_5.png")),
      caption: [
        Images to use in further analysis
      ],
      label: <fig:sam:images>,
    )

    == Strategies for input prompt generation <section:sam:strategies>
    The following discussion will address the methodology for prompting #abr("SAM").
    Firstly, it is important to note that prompting by bounding box will not be of assistance in this instance.
    The image has already been cropped to primarily depict the roof.
    In the event of the bounding box provided to #abr("SAM") being a bounding box around individual segments, it would be necessary to have the same segments that are being attempted to be calculated. This would also be an ineffective process.
    The utilisation of this method would facilitate the enhancement of segmentation, particularly in scenarios where accurate estimates of the segment and its boundaries have been previously determined.
    However, this topic will not be pursued further in this discussion.

    Instead, this evaluation will formulate strategies for input point prompting, since for this purpose, a rough estimate on the surface will suffice to ascertain that it is a single point definitively inside the correct segment.
    This approach provides a significant advantage by eliminating the need to identify initial segments of moderate quality, particularly with regard to completeness. Instead, it focuses on locating segments that, in theory, do not span multiple true segments and persist, ideally capturing most of the useful points for #abr("SAM").
    Further elaboration on the generation of these surfaces can be found in @section:ndsm_analysis.

    The following strategies will be employed to break down any given surface to a set of points.
    The implementation of each of these strategies is outlined in the appendix.

    #heading(depth: 5, numbering: none, bookmarked: false)[Random Strategy]
    The initial concept was to utilise any arbitrary point, randomly chosen within a specified surface. 
    Alternatively, an enhancement was proposed that would not be confined to a single point, but would be capable of defining multiple points.
    This random strategy is elementary and served well for preliminary experiments; however, it was also quickly discarded.
    The underlying reason for this phenomenon is that the generation of random points can result in a disproportionately high degree of variability in the results.
    It is important to note that the configuration of points can yield significantly better results than another.
    It would be possible to employ countermeasures in response to this issue. 
    These could include the repeated execution of the process, with all available results subjected to thorough analysis, or the implementation of a sophisticated approach to ensure that the points are distributed in a uniform manner.
    A statistical analysis could be conducted to ascertain the probability of the results being statistically significant, or to determine the likelihood of the result being correct at least a certain percentage of the time, or at least correct to a certain degree.

    However, this was deemed to lack plausibility and constructiveness.
    Instead, a more deterministic approach was adopted in order to achieve enhanced results and facilitate the comparison of the various strategies.

    #heading(depth: 5, numbering: none, bookmarked: false)[Center Strategy]
    The second strategy involves the selection of the centre point of the surface as the input point.
    The centre point is defined as the point that is located at the centroid of the surface's geometry. 
    Alternatively, it may be defined as the closest point to the centroid which also lies within the surface, sinc this is not guaranteed, for example, if another surface lies within the current one.
    This methodology establishes a deterministic point extraction technique that exhibits no variability when compared with the random strategy.

    It is hypothesised that points in closer proximity to the edge of the surface are more likely to result in erroneous segmentations.
    Consequently, a failsafe mechanism will be implemented that will attempt to move any such point towards the nearest point that is not on the surface's edge.

    In instances where the number of points exceeds one, the algorithm endeavours to distribute them proportionally.
    It is acknowledged that this is not achieved in the most sophisticated manner; however, further improvement would only be implemented if a need emerged for it due to substandard quality.
    Moreover, the hypothesis was formulated that, in place of employing the centroid by value weighing, the surface could be eroded until no points remained.
    The last points removed would thus represent the most interior points of the surface.
    Nevertheless, this approach was not pursued any further, as the hypothesis was only conceived at the end of the research process.

    #heading(depth: 5, numbering: none, bookmarked: false)[Combined Strategy]
    The third strategy is an evolution of the Center Strategy.
    The underlying principle is to create a specific number of centre points within a given surface.
    In addition to the aforementioned points, this strategy also incorporates a certain number of negative points stemming from other surfaces.
    In order to circumvent the introduction of randomness, the algorithm systematically selects a single negative centre point for each other surface, with the selection initiated from the largest surface.
    A more sophisticated approach to the selection of negative points is possible, but at this stage the focus is on establishing the proof of concept that negative points may improve results.

    #heading(depth: 5, numbering: none, bookmarked: false)[Synopsis]
    The @fig:sam:strategy_example illustrates the three strategies that were employed to create input prompts.
    The segmentation employed for the purpose of visualisation in this instance is derived from a later iteration of the segmentation process.
    Nevertheless, it serves to demonstrate how the different strategies, with different configurations, distribute points across the surface.
    In this particular system, points that are utilised for the purpose of positive inputs are denoted with a green colour. 
    Conversely, negative points, which are incorporated within the Combined Strategy, are represented by being coloured red.
    It is observable, that the distribution of points is subject to significant variation when utilising the Random Point Strategy.

    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../data/6/1/sam/strategy_example.png")),
      caption: [
        Input prompts example for strategies
      ],
      label: <fig:sam:strategy_example>,
    )

    == Prompting Techniques and Results

    === Manual Prompting
    In order to develop a more complete understanding of the capabilities and limitations of #abr("SAM"), an initial experiment was conducted using manual prompting with input points.
    There are a number of tools available online that can facilitate this kind of interaction. 
    These tools enable users to supply positive and negative points, thus guiding #abr("SAM") in generating segmentations.
    In addition to employing pre-existing tools, a small custom interface was developed for the purpose of manually annotating images with point-based prompts, incorporating both positive and negative input prompts.
    This configuration facilitated more rigorous experimentation and direct engagement with the model.

    However, the results indicated a substantial limitation: the quality of individual segmentations frequently fell short of the requirements for high-precision tasks.
    Masks frequently necessitated substantial manual refinement and correction.
    The manual effort required to achieve satisfactory results was found to be greater than the practical benefit in most cases.
    This emphasised the necessity for more automated or structured approaches to prompting in order to generate masks that are consistently useful, particularly for complex scenes or high-level semantic segmentation.

    === Automatik Mask Generator
    One simple way of using #abr("SAM") is by using the automatic mask generator provided by the #abr("SAM")2 implementation.
    This class lays a regular grid over the image and prompts the model with these points.
    Afterwards, the results are subject to multiple post processing steps like non-maxmimum suppression and thresholding to create the final segmentation over the entire image @sam4.
    This appraoch does not requier us to create reliable input prompts, but also disenables further control over the specific data used as input.

    The @fig:sam:automatic illustrates the results of utilising the automatic mask generator on the established input images.
    The results obtained are extremely encouraging, as they indicate with a high degree of certainty that #abr("SAM") is capable of delivering the desired segmentations.
    A substantial number of segments were detected, and the roof's overall shape is adequately captured.
    Nevertheless, certain segments are absent, and even minor surfaces appear to be subject to a high degree of certainty according to the scoring system.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/0.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      box(figure(image("../data/6/1/sam/1.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      box(figure(image("../data/6/1/sam/2.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      box(figure(image("../data/6/1/sam/3.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      box(figure(image("../data/6/1/sam/4.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      box(figure(image("../data/6/1/sam/5.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in)),
      caption: [
        Segmentations using the Automatic Mask Generator
      ],
      show-sub-caption: (num, it) => {
        [#it.body]
      },
      label: <fig:sam:automatic>,
    )

    The utilisation of the generator is associated with a number of challenges.
    The outcomes are contingent on the precise values of the algorithm's hyperparameters, including the threshold for non-maximum suppression and the minimum threshold for a mask's stability score.
    In order to ascertain the most effective manner in which to utilise this method, it would first be necessary to research and experiment with the precise parametrisation.
    However, these endeavours will not be pursued further.
    Instead, the subsequent phase of research will be dedicated to the development of custom input prompts, better designed for individual surfaces, with the objective of achieving image segmentation.

    === Input Prompting
    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    The following results, presented in @fig:sam:mask_all, represent example outcomes achieved through prompting #abr("SAM") with the mask as the input.
    The second column shows the ground truth for visual confirmation of the expected result.
    Further elaboration on this topic can be found in @section:ground_truth.
    Whilst the general structure of the roof is adequately depicted, the individual segmentations are not without fault.
    It is evident that the model is deficient in its provision of precise input prompts for smaller surfaces and details.
    Segments of the building that are enclosed, such as chimneys and balconies, are particularly affected.
    All segmentation that were created during testing, across all strategies and all input images, demonstrated these issues.

    It is evident that the quality of the output is significantly influenced by the quality of the input mask. The input mask, which is of substandard quality, is incapable of providing reliable results, as discussed in @section:input_data.
    In certain instances, the correct segmentation appears to be a coincidental outcome of randomly effective input masks, as opposed to a systematic functionality of the algorithms.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../data/6/1/image.png", width: 100%)),
      figure(image("../data/6/1/truth.png", width: 100%)),
      figure(image("../data/6/1/mask.png", width: 100%)),
      figure(image("../data/6/1/sam/best/mask.png", width: 100%)),

      figure(image("../data/6/18/image.png", width: 100%)),
      figure(image("../data/6/18/truth.png", width: 100%)),
      figure(image("../data/6/18/mask.png", width: 100%)),
      figure(image("../data/6/18/sam/best/mask.png", width: 100%)),

      figure(image("../data/6/19/image.png", width: 100%), caption: [Image]),
      figure(image("../data/6/19/truth.png", width: 100%), caption: [Ground Truth]),
      figure(image("../data/6/19/mask.png", width: 100%), caption: [Mask]),
      figure(image("../data/6/19/sam/best/mask.png", width: 100%), caption: [Output]),
      caption: [
        Using SAM with input prompts from the mask
      ],
      show-sub-caption: (num, it) => {
        [#it.body]
      },
      label: <fig:sam:mask_all>,
    )

    The Combined Point Strategy was found to be even more dependent on the random quality of the input mask.
    For a number of houses, the impact of negative points was negligible.
    In other cases, the negative points had a highly detrimental effect on the results.
    However, these results are broadly in line with expectations.
    The underlying principle of negative point is to provide indications to the #abr("SAM") of regions within the image that fall outside the current surface.
    In the event of the mask being segmented incorrectly, negative points selected in this manner may well be found in the real segment currently under investigation.
    Consequently, the evaluation of the effectiveness of the proposed measures will be postponed.

    #heading(depth: 5, numbering: none, bookmarked: false)[Analysing the individual masks per segment]
    As illustrated by @fig:sam:mask_masks, the results for each input image are demonstrated using the Center Point Strategy, with two positive input points per surface.
    The upper section of the figure illustrates the overall segmentation result.
    In the section below, the performance of each individual mask by #abr("SAM") is displayed, along with the score assigned by the model to that segmentation.
    For the purpose of illustration, solely the rows with the four largest input segments are displayed.

    It has been demonstrated that certain segments are capable of being effectively segmented by the use of specific input images. 
    Conversely, #abr("SAM") has been observed to be incapable of identifying the same segment when other input images are employed.
    This is exemplified by the second row of masks, where #abr("SAM") is incapable of identifying the segment on the derivative imag.
    In the final row of masks, the results run on the images employing #abr("RGB")  data incorporate an erroneous segment to the right.
    However, the derivative image is able to clearly differentiate between the two with a high degree of certainty, as evidenced by the particularly high score of 0.937.
    This finding indicates the possibility of combining the masks in a manner that may yield a more effective segmentation.
    The evaluation of this suggestion is to be postponed until a later point in the research process.

    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      box(figure(image("../data/6/19/sam/mask/result.png")), clip: true, width: 100%, inset: (bottom: -0in)),
      box(figure(image("../data/6/19/sam/mask/masks.png")), clip: true, width: 100%, inset: (bottom: -6.2in, top: -0.9in)),
      caption: [
        Best mask per input image and input segment
      ],
      label: <fig:sam:mask_masks>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Premediary Conclusion]
    The preliminary findings suggest that the utilisation of #abr("SAM") for the purpose of generating high-quality segmentations is a promising avenue for exploration.
    A more in-depth analysis of the results is required in order to ascertain the most effective input data and input strategy.
    Prior to this, however, it will be necessary to replace the mask's utilisation for input prompt generation.
    It is essential to establish a robust methodology for generating reliable prompts from the input data, with a objective of enhancing the segmentations.
    The subsequent chapter will thus be dedicated to the analysis of the input data from an algorithmic perspective.
    The objective is to devise prompts that accurately reflect the real data. 
    In the process, an objective method of evaluating segment quality is to be developed, since the confidence scores provided by #abr("SAM") are not reliable indicators of the ground truth.
  ]
}