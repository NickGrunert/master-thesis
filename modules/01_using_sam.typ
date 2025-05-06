#import "@preview/subpar:0.2.0"

#let sam() = {
  text(lang:"en")[
    = Segment Anything Model (SAM)
    In this chapter, we will initiate the experimental phase concerning the usability of SAM in the context of roof segmentation.
    The objective is to ascertain the necessary input data to facilitate effective segmentations and to determine the optimal utilization of SAM to achieve this objective.

    == Images
    This section will shortly list the types of images that will be used in the evaluation.
    While other concepts were briefly explored, none of these approaches represented novel methodologies and were met with very limited success.
    The objective of this section is to identify promising candidates of images, data, or preprocessing steps that have the potential to serve as input data for the SAM model to subsequently generate segmentations displaying the roof shape.

    #heading(depth: 5, numbering: none, bookmarked: false)[RGB Image]
    One of the images that can be used is the original RGB image itself.
    However, it should be noted that the utilization of RGB data does not provide additional height information and presents certain challenges.

    For instance, the presence of shadows within the data can result in severe misclassifications, as the model may lack the capacity to differentiate between the shadow and the object.
    It has been observed that, due to geometric constraints, the majority of surfaces are either wholly shaded or wholly illuminated; however, this is not guaranteed.
    In the context of color channel manipulation, particularly in the red, green, and blue channels, the presence of shadows can result in strongly divergent values across all three channels. 
    This phenomenon hinders the effectiveness of an algorithm in identifying similarities between segments that are not shaded and those that are shaded.

    Shadows are a prominent feature of the input data, attributable to the geographical location of Germany, which results in a sun position that casts shadows on a significant proportion of residential structures.
    In order to enhance the utilization of the raw RGB data, an algorithm for shadow removal is implemented. 
    This algorithm utilizes Gaussian kernels to identify and eliminate shadowed regions @shadows1 @shadows2 @shadows3.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../data/6/19/image.png", width: 50%)),
      figure(image("../data/6/19/sam/shadow_removed_image.png", width: 50%)),
      caption: [
        Comparison between Image and Shadow Removed Image.
      ],
      label: <fig:sam:shadows>,
    )

    As demonstrated by @fig:sam:shadows, a clear distinction emerges between the original image and the shadow removed image.
    The efficacy of the shadow removal algorithm is questionable. 
    It is evident that the algorithm modifies the overall coloration of the image. 
    This modification may be advantageous in that it prevents the algorithm from being distracted by color changes across a coherent surface.
    The presence of discernible boundaries within the color channels is indicative of a failure to effectively differentiate between surfaces.
    This finding merits further consideration in subsequent experiments. 
    The objective of these experiments is to ascertain whether the shadow removal algorithm can enhance the segmentation results of the SAM model.

    #heading(depth: 5, numbering: none, bookmarked: false)[nDSM Image]
    Due to the fact that the RGB data contains a substantial amount of information that is either not beneficial or even detrimental when provided to SAM, we will try to enhance the input data by using the nDSM data.
    The nDSM data contains the height information of the current image frame.
    The incorporation of this data is expected to result in enhanced quality, as it is considered to be valuable information regarding the surface structure.

    #subpar.grid(
      columns: 5,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/sam_mask.png")), clip: true, width: 100%, inset: (right: -2.9in)),
      caption: [
        nDSM Image.
      ],
      label: <fig:sam:images:ndsm>,
    )

    However, the utilization of nDSM data as SAM input appears to be unfeasible in a direct manner.
    This thesis is the result of a thorough analysis of @fig:sam:images:ndsm.
    This phenomenon is evidenced by the minimal contrast present in the image, indicative of its limited information content.
    However, the value graph distinctly demonstrates the potential for differentiating between the roof and the ground.
    As this topic has not been the primary focus of the present discussion, further examination of it will be reserved for a later in @section:replace_clipping_by_sam.








    #heading(depth: 5, numbering: none, bookmarked: false)[Custom Derivative Image]
    ```python
    def get_color(x, y):
      magnitude = np.sqrt(x**2 + y**2)

      if x >= 0 and y >= 0:
          # Red for Quadrant I
          return (magnitude, 0, 0)
      elif x < 0 and y >= 0:
          # Green for Quadrant II
          return (0, magnitude, 0)
      elif x < 0 and y < 0:
          # Blue for Quadrant III
          return (0, 0, magnitude)
      else:
          # Yellow for Quadrant IV
          return (magnitude, magnitude, 0) # Yellow = Red + Green
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Color Channel Swaps]

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 5,
      gutter: 2mm,
      box(figure(image("../data/6/1/sam/0.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/1.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/2.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/3.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      box(figure(image("../data/6/1/sam/4.png")), clip: true, width: 100%, inset: (right: -1.2in, top: -0.15in)),
      caption: [
        Image Types which will be used in further Analysis.
      ],
      label: <fig:sam:images>,
    )
      




    == Input Prompting



    #heading(depth: 5, numbering: none, bookmarked: false)[Random Strategy]

    #heading(depth: 5, numbering: none, bookmarked: false)[Center Strategy]

    #heading(depth: 5, numbering: none, bookmarked: false)[Combined Strategy]

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../data/6/1/sam/strategy_example.png")),
      caption: [
        Input Prompts depending on Strategy and Parameter.
      ],
      label: <fig:sam:strategy_example>,
    )




    == Results



    #heading(depth: 5, numbering: none, bookmarked: false)[Automatic Mask Generator]
    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../data/6/1/sam/0.png"), caption: [
        RGB Image.
      ]), <fig:sam:automatic:a>,
      figure(image("../data/6/1/sam/1.png"), caption: [
        Derivative Image.
      ]), <fig:sam:automatic:b>,
      figure(image("../data/6/1/sam/2.png"), caption: [
        Red Channel Swapped.
      ]), <fig:sam:automatic:c>,
      figure(image("../data/6/1/sam/3.png"), caption: [
        Green Channel Swapped.
      ]), <fig:sam:automatic:d>,
      figure(image("../data/6/1/sam/4.png"), caption: [
        Blue Channel Swapped.
      ]), <fig:sam:automatic:e>,
      caption: [
        Result Segmentations using the Automatic Mask Generator.
      ],
      label: <fig:sam:automatic>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Input Prompting]
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

      figure(image("../data/6/19/image.png", width: 100%)),
      figure(image("../data/6/19/truth.png", width: 100%)),
      figure(image("../data/6/19/mask.png", width: 100%)),
      figure(image("../data/6/19/sam/best/mask.png", width: 100%)),
      caption: [
        Using SAM with Input Prompts from the Mask.
      ],
      label: <fig:sam:mask_all>,
    )
  ]
}