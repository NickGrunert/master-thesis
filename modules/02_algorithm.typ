#import "@preview/subpar:0.2.0"

#let ndsm_analysis() = {
  text(lang:"en")[
    = Creation of reliable Input Prompts
    As a need for more reliable input promps emerged, this section will discuss the process of programming a custom pipeline to create segmentations.
    These segmentation are to be more trustworthy for prompting SAM, and therefore should result in overall better outputs.
    This will serve the purpose of truly being able to identify whether SAM is capable of solving the given problem or if even after having improved the input data given to it it still fails to satisfy requirements.
    This means that this section works based on the hypothesis that correct input points lead to better segmentations by SAM.
    This not only includes better segmentations in terms of structural correctness, as that was not a given when using the input mask, but especially includes a more correct number of input points.
    This should in theory then solve the problem that small surfaces were not able to be predicted since there was not prompt given for them.

    The following oberservations and assumptions are made in this section:
    - In comparison to the nDSM data, the original RGB pictures contain almost no relevant information.
      The nDSM data containing the buildings house data is fully capable of serving the relevant information which a segmentation algorithm needs for successful identification of the roof's structure.
      The following sections will therefore not make use of the RGB data but solely focus on height information.
    - Using the nDSM data however entails having the need to be able to handle it's multiple flaws.
      For example, most surfaces will not have perfectly smooth derivative data due to seemingly random instabilities inside the given data.
      The height values of a structurally normal  roof segment sould in theory be piecewise representable as a continuous function, meaning that the derivative values should be similar or rather constant across the whole surface, which is however disrupted by such abnormalties.
      Therefore, the algorithm will be forced to handle such errors and ensure they do not invalidate it's output.
      Invalidation hereby means that such occurences do not lead to mayor miscategorizations of segments.

    The present chapter is composed of three sections.
    @section:algorithm will encompass a comprehensive discussion of the algorithmic components that facilitate the generation of custom segmentation for any given house.
    In this section, the discussion will center on the introduction of select hyperparameters that have demonstrated potential in facilitating the algorithm's adaptability to variable scenarios.
    Therefore, the section introduces a scoring algorithm that aims to evaluate the quality of a given segmentation. This evaluation process serves to determine whether parameter adjustment is necessary.

    Consequently, the @section:truth_compare will generate some ground truth examples to ascertain the system's reliability and the effectiveness of the scoring system.
    These metrics will be employed to derive an objective score for statistical analysis and comparison.
    
    Lastly, @section:ablation of this chapter will then return to said parameter and perform an ablation study on the actual effect of these, intended for the purpose of achieving a better understanding and filtering out those parameter with minor effect so that they will not be considered in further calculations on unseen data.

    == Identification of Roof Structures through Analysis of nDSM Data <section:algorithm>
    In the following sections, the nDSM data will be utilized to calculate derivatives, process the data, and consequently detect edges inside the image.
    The derivatives are generally distinguished between x and y directions.
    The utilization of combined values, expressed as magnitudes, is not a viable approach. 
    In the context of mathematics, the operation of multiplying "x" by "-y" is equivalent to the inverse operation of multiplying "-x" by "y."
    However, in practical applications, it is essential to differentiate between these two cases.
    This predicament stems from the problem of opposing roofs having mirrored signs, which is most problematic on axis-aligned houses, where the resulting magnitude of opposing roofs can be identical.
    Consequently, the algorithm may interpret these surfaces as identical, despite substantial disparities in their individual x and y values.

    Derivatives are constructed using appropriate algorithms as outlined in the @section:edge_detection. 
    Subsequently, the algorithm implements a series of transformations: logarithmic scaling in @section:log, clipping in @section:clipping, and Gaussian blurring in @section:gaussian_blurring. 
    The purpose of these transformations is to enhance contrast and remove noise, thereby facilitating improved algorithmic analysis.
    In conclusion, @section:canny will outline the utilization of the Canny Edge Detection algorithm.
    Subsequently, the edges originating from the x and y directions are combined through the application of logical or, thereby yielding the final edges.
    Lastly, @section:edges:results outlines the combined steps which make up the overall edge detection pipeline.
    
    === Edge Detection <section:edge_detection>

    #heading(depth: 5, numbering: none, bookmarked: false)[Kernel]
    $ "Sobel": G_x = mat(
      -1, 0, 1;
      -2, 0, 2;
      -1, 0, 1;
    ) "  and" G_y = mat(
      -1, -2, 1;
      0, 0, 0;
      1, 2, 1;
    ) $ <formula:sobel>

    $ "Scharr": G_x = mat(
      -3, 0, 3;
      -10, 0, 10;
      -3, 0, 3;
    ) "and" G_y = mat(
      -3, -10, 3;
      0, 0, 0;
      3, 10, 3;
    ) $ <formula:scharr>

    $ f′(x_i) ≈ (f(x_i+1)-f(x_i-1)) / (2h) $ <formula:gradient>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    There exists a multitude of methodologies for the calculation of derivatives with regard to two-dimensional image data.
    The Sobel and Scharr operators are common approximation method frequently employed for this purpose.
    The two methods under discussion are based on the idea of using convolution, whereby a specific kernel is slid over the image, calculating the derivative at each pixel.
    Given that the kernels employed are of sizes 3x3 or 5x5, these are approximations, since the derivative should typically consider only the two pixels directly adjacent to it.
    In essence, the functionality of both operators is equivalent; the only discrepancy lies in the kernel utilized, as illustrated by @formula:sobel and @formula:scharr @ScharrOperator @SobelOperator @derivative_sobel1.

    A more conventional way of calculating the derivative is to interpret each row and column as a function defining the values x and then to use the standard mathematical approach demonstrated by @formula:gradient. 
    Here, the derivative is calculated by taking the difference between two adjacent pixels and dividing it by the distance between them. 
    Since the distance between two pixels is always 1, the parameter h can be omitted. 
    While this is theoretically the most mathematically accurate way of calculating the derivative, it is also the most computationally expensive, since the kernel convolution can be optimized quite efficiently. 
    Nevertheless, it is definitely a promising approach and will be included in the algorithm for later evaluation. 
    A fourth method, called the sliding window approach, mimics the novel approach of calculating the gradient without the mathematical correctness of the division by $2h$. 
    This was used as a kind of test alongside the other methods, just for experimentation.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    While all of the following implementations do not distinguish between the x and y directions, in this single section it is necessary due to implementation details where they need to be handled separately.
    The possible derivatives are defined via an enum for better identification and case matched inside the edge detection algorithm.
    The Scharr Method uses a Sobel kernel with -1, which is defined in the cv2 documentation as a standard 3x3 Scharr kernel @derivative_sobel1.
    Gradient calculation is implemented using the numpy gradient function @gradient.

    ```python
    class DerivativeMethod(Enum):
      SOBEL = 0
      SLIDING = 1
      GRADIENT = 2
      SCHARR = 3

    def edge_detection(...):
      derivative = params.derivative

      # Initial normalization
      n = cv2.normalize(entry['ndsm'], None, 0, 255, cv2.NORM_MINMAX)

      ####### STEP 1 : DERIVATIVE
      match derivative:
        case DerivativeMethod.SOBEL:
          x = cv2.Sobel(n, cv2.CV_64F, 0, 1, ksize=3)
          y = cv2.Sobel(n, cv2.CV_64F, 1, 0, ksize=3)
        case DerivativeMethod.SLIDING:
          kernel = np.array([1, 0 , -1])
          y = np.apply_along_axis(
            lambda row: np.convolve(row, kernel, mode='same'), axis=1, arr=n)
          x = np.apply_along_axis(
            lambda col: np.convolve(col, kernel, mode='same'), axis=0, arr=n)
        case DerivativeMethod.GRADIENT:
          x, y = np.gradient(n)
        case DerivativeMethod.SCHARR:
          x = cv2.Sobel(n, cv2.CV_64F, 0, 1, ksize=-1)
          y = cv2.Sobel(n, cv2.CV_64F, 1, 0, ksize=-1)
        case _: # Catch-all for unmatched cases
          raise ValueError(f"Unexpected derivative type: {derivative}")

      # ... other steps
    ```

    ==== Applying Logarithmic Scaling <section:log>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    There are many ways to improve the contrast of images @log3.
    This subsection will focus on one such chosen method, namely using applying a logarithmic transformation to the input data.
    A higher contrast is generally helpful for visual confirmation, as well as presumably helpful for the general performance of the algorithm.
    At the very least, the visual appeal of the intermediate derivative image is greatly improved, making most values and edges more distinguishable.
    The strong effect of this can be seen in @fig:algorithm:log, where not only a visual distinction is possible only after scaling, but also the distribution plot clearly reflecting better utilization of the value spectrum.

    This is due to the analysis of the derivative data, which shows that even after normalization, the derivative data consists of mostly dark values clustered around zero, since there are some extreme outliers in the data, creating a highly uneven distribution of values.
    It is shown that such distorted data can be made more robust for analysis by applying the logarithm to it @log1.
    General image analysis seems to be improved by such transformations @log2.

    #subpar.grid(
      columns: 3,
      gutter: 1mm,
      box(figure(image("../figures/apply_log/original_data/no_log.png")), clip: true, width: 100%, inset: (right: -19in, bottom: -4.0in)),
      box(figure(image("../figures/apply_log/original_data/no_log.png")), clip: true, width: 100%, inset: (right: -6in, left: -1in, bottom: -0.8in)),
      box(figure(image("../figures/apply_log/original_data/log.png")), clip: true, width: 100%, inset: (right: -6in, left: -1in, bottom: -0.8in)),

      box(figure(image("../figures/apply_log/original_data/round_no_log.png")), clip: true, width: 100%, inset: (right: -19in, bottom: -4.0in)),
      box(figure(image("../figures/apply_log/original_data/round_no_log.png")), clip: true, width: 100%, inset: (right: -6in, left: -1in, bottom: -0.8in)),
      box(figure(image("../figures/apply_log/original_data/round_log.png")), clip: true, width: 100%, inset: (right: -6in, left: -1in, bottom: -0.8in)),
      caption: [
        Impact of applying the logarithm on derivative data.
      ],
      label: <fig:algorithm:log>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    The following implementation stores the sign of each value first, because the logarithm is not defined for negative values.
    Therefore, after applying the logarithm to the absolute derivative values, they are normalized and multiplied by the original sign.
    In this way, the logarithm can be applied while preserving the original sign of the derivative values, i.e. without losing the differentiability of the derivative direction.

    Note that the neutral value 0 will most likely be moved away from the origin in one of the following steps.
    This is because to solve this problem, the algorithm would have to treat positive and negative values completely separately, or else the normalization would cause this effect.
    However, this effect has shown up only rarely in experiments, and even when it does occur, it has not proven to have a negative effect on results, or rather, in some experiments, handling it had a negative effect.

    This observation will not be analyzed further, and the decision has been made to simply always use the logarithm; no extensive experimentation and analysis will be done to understand the effect of this further.
    Later, results will be shown where this effect can be seen by slightly coloring the segments, where the expected result would be a mean derivative of 0 for exemplary flat roofs.
    If the specific segment is slightly colored, this is most likely due to this effect.

    ```python
    def edge_detection(...):
      # ... other steps

      ####### STEP 2 : LOGARITHMIC SCALING
      # Store the sign of the original derivatives
      sign = np.sign(derivative)

      # Apply log1p to the absolute values
      log = np.log1p(np.abs(derivative))

      # Normalize the logarithmic values
      derivative = cv2.normalize(log, None, 0, 255, cv2.NORM_MINMAX)

      # Reapply the original sign
      derivative = derivative * sign

      # ... other steps
    ```

    ==== Clipping extreme Values <section:clipping>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    A visual analysis of the individual steps during the initial setup of this pipeline has revealed some statistical constants across the different data sets.
    This includes the observation that the edge surrounding the house consistently exhibits the most extreme derivative values.
    Despite the potential presence of high-order derivatives aside from these, the following observation holds: the precise difference between such extreme derivatives is inconsequential. 
    Consequently, the clipping of those values followed by normalization positively enhances the contrast of the image, thereby facilitating the evaluation process for the algorithm without the loss of crucial information.

    In this context, setting the clipping percentage to 10 percent entails the reduction of the highest and lowest 10 percent values.
    It is evident that, given the normalization of the values preceding this step, the derivative values between $[-255, 255]$, in this example, will be set to $[-230, 230]$. Consequently, all values that fall outside this range will be set to the new extrema.

    It has also demonstrated that interpreting the actually clipped values as edges and executing the surface generation steps on them can function as a mask for base area detection, as will be discussed in @section:surfaces:filtering.
    The direct effect of this is shown in @fig:algorithm:clipping, which shows the difference between applying 0 and 7 percent clipping.
    While no clipping shows very low distinguishable values, the shape of the roof becomes visible after the clipping is applied.
    Inside the value graph, the hills representing the individual segments become visible.
    It should be noted that in the example shown no normalization was applied, but the general effect is not affected by this.
    Said theory of base area detection can also be seen in the visualization of the clipped values in the bottom column of the graphs.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      box(figure(image("../figures/clipping/0.png"), caption: [0%]), clip: true, width: 100%, inset: (bottom: 0.1in, left: -4.3in, right: -4.3in)),
      box(figure(image("../figures/clipping/7.png"), caption: [7%]), clip: true, width: 100%, inset: (bottom: 0.1in, left: -4.3in, right: -4.3in)),
      caption: [
        Comparison between applying 0 and 7 percent clipping.
      ],
      label: <fig:algorithm:clipping>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    The implementation of this process is a relatively uncomplicated matter.
    The algorithm does not make any assumptions regarding the distribution of derivatives. 
    It also does not calculate individual threshold values depending on the actual distribution between negative and positive values.
    Instead, the values on each side are taken equally.
    The values that were clipped will be saved for later use in the surface generation step.

    ```python
    def edge_detection(...):
      percent = params.clipping_percentage

      # ... other steps

      ####### STEP 3 : CLIPPING
      lower_bound = np.percentile(derivative, 0 + percent)
      upper_bound = np.percentile(derivative, 100 - percent)
      clipped = np.clip(derivative, lower_bound, upper_bound)

      # Save clipped values
      mask = (derivative != clipped)
      clipped_values[name] = mask

      # ... other steps
    ```

    ==== Gaussian Blurring <section:gaussian_blurring>
    #heading(depth: 5, numbering: none, bookmarked: false)[Kernel]
    $ "Gaussian 3x3" = 1 / 4.672 * mat(
      0.210, 0.458, 0.210;
      0.458, 1.000, 0.458;
      0.210, 0.458, 0.210;
    ) $ <formula:gaussian_kernel>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    Overall, the derivative is very noisy due to inconsistencies in the input height information.
    To address this issue, the algorithm will use Gaussian smoothing for noise reduction.
    A 2-dimensional kernel approximating a Gaussian is used to apply a convolution to the image.
    This blurs the entire image @Gauss1.

    Using the OpenCV Gaussian blur implementation @Gauss2 introduces several new possible parameters, the kernel size and sigma values.
    The sigma values define the standard deviation of the Gaussian function, which in turn determines the amount of blur applied to the image.
    However, the influence of these parameters will not be explored extensively, and only 3x3 and 5x5 kernels will be tested, as well as whether noise reduction has the desired positive influence at all.
    The sigma values are not explicitly set, so the algorithm automatically calculates them to be $≈0.8$ and $≈1.1$ for 3x3 and 5x5 kernels respectively.
    @formula:gaussian_kernel shows the mathmatically correct Gaussian 3x3 kernel using the given parameter.
    It is noteworthy that the OpenCV kernel deviates marginally at the four edge values due to the implementation of corrections, which results in a kernel sum that approaches closer to 1 to reduce errors.

    The position in the overall edge detection pipeline just before Canny Edge Detection is applied and after the derivatives have been computed and clipped was determined after some minor experimentation that proved less successful than placing it here.
    Note that due to the small size of the image, this blurring leads to a loss of detail, which will mean problems in detecting thin roof parts.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    ```python
    class BlurringMethod(Enum):
        NONE = 0
        SMALL = 1
        MEDIUM = 2

    def edge_detection(...):
      # ... other steps

      clipped = cv2.normalize(clipped, None, -255, 255, cv2.NORM_MINMAX)

      ####### STEP 4 : GAUSSIAN BLURRING
      match apply_blur:
        case BlurringMethod.NONE:
          blurred = clipped
        case BlurringMethod.SMALL:
          blurred = cv2.GaussianBlur(clipped, (3, 3), 0)
        case BlurringMethod.MEDIUM:
          blurred = cv2.GaussianBlur(clipped, (5, 5), 0)
        case _: # Catch-all for unmatched cases
          raise ValueError("Unexpected blurring type")

      # ... other steps
    ```

    ==== Canny Edge Detection <section:canny>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    The concluding step of this section involves the implementation of the Canny Edge Detection algorithm @Canny1.
    The employment of the Canny algorithm enables the flexible adaptation of the system to the unique characteristics and requirements of each individual house.
    The underlying rationale for this phenomenon stems from the implementation of a complex calculation method that utilizes two parameters, lower and upper thresholding, to filter out edges based on gradient magnitude @Canny2.

    It should be noted that alternative edge-detection algorithms could have been considered.
    Algorithms of a simpler nature are based on the gradient value between the x and y directions of the image.
    Nonetheless, such filters—for instance, the Sobel filter—are often found to be inadequate, particularly in noisy environments @Sobel2.
    A substantial number of comparisons between Sobel and Canny detection have been documented.
    The Sobel filter's most notable strength is its simplicity, which is advantageous in applications where rapid execution is paramount @Sobel1.
    However, the temporal efficiency of the process is not a primary concern; instead, the emphasis is placed on the quality of the results obtained.
    Canny's superior performance is attributable to its capacity for enhanced parameter tuning, a feature that is particularly advantageous in achieving more precise edge detection @Sobel3. 
    This is a notable benefit, given that this work does involve the use of low-resolution images.

    The determination of the optimal values for the lower and upper threshold will necessitate a process of experimentation and will vary between houses.
    There have been suggestions of dynamically calculating the threshold values based on the gradient's median value @Canny3. 
    However, this was not implemented due to initial tests not yielding promising results.
    Conversely, the algorithm will utilize dynamic percentage thresholds.
    It is important to acknowledge that this approach will essentially replicate the utilization of absolute values directly, as the data undergoes normalization to fall within the range of 0 to 255 prior to the application of the Canny algorithm.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    It is crucial to note that the Canny algorithm exclusively accepts positive integer inputs.
    The negligible loss of information when transitioning from $[-255, 255]$ to $[0, 255]$, which entails halving the value range, is an inherent risk and is presumed to exert a negligible effect on the outcomes, at most.

    The threshold values are designated as the lower and upper percentiles of the normalized image.
    While they are set at equal intervals in this instance for the sake of simplicity, they can be adjusted to allow for uneven percentiles in the future, should preliminary results prove unsatisfactory.
    For instance, setting the percentage to 35 will result in a threshold of $[89, 179]$, a representation that nearly perfectly aligns with the novel approach of setting the upper threshold at double the lower threshold.

    ```python
    def edge_detection(...):
      lower = params.canny_values[0]
      upper = params.canny_values[1]

      # ... other steps

      ####### STEP 5 : EDGE DETECTION
      normalized = cv2.normalize(
          blurred, None, 0, 255, cv2.NORM_MINMAX, cv2.CV_8U
      )

      lower_threshold = int(np.percentile(normalized, lower))
      upper_threshold = int(np.percentile(normalized, upper))
      edges = cv2.Canny(normalized, lower_threshold, upper_threshold)

      # ... other steps
    ```
    
    ==== Results <section:edges:results>

    #figure(
      image("../figures/edge detection/pipeline1.png", width: 100%),
      caption: [
        Edge Detection Pipeline.
      ],
    ) <fig:algorithm:edges:pipeline>

    @fig:algorithm:edges:pipeline demonstrates the full pipeline that was utilized for the edge detection step.
    The derivatives for each step are assigned a color, ranging from blue to red, with blue signifying negative values and red denoting positive ones.
    Given that these are divided into the x and y directions, this coloration method is adequate.

    It should be noted that the parameters were not optimized for this specific image, but are exclusively utilized for illustrative purposes here.
    For instance, given the absence of substantial outliers in the image, which would typically serve to diminish contrast, it is plausible that the clipping value was set at an excessively high value. 
    This hypothesis is substantiated by observation of the distribution charts.
    The impact of blurring is discernible, as the surface coloration exhibits a more polished and smooth appearance subsequent to the application of this technique.

    === Surface Growth <section:surface_growth>

    // TODO

    ==== Surface Growth
    Using the edges computed in the edge detection pipeline, the algorithm is able to generate surfaces.
    First, filter out all edge pixels and consider only non-edge pixels.
    Assign one of them as a surface, then iteratively append all adjacent pixels from the list of non-edges until no connected pixels remain.
    If there are no appended non-edge pixels left, assign one of them as a new surface and repeat the process.
    This continues until all pixels are assigned.
    There is no parameterization required and no edge cases that need to be considered.

    ==== Separation and Relinking
    Next, the algorithm takes the generated surfaces and splits them on pixels that do not belong to edges but are adjacent to an edge, before attempting to reconnect such separated surfaces if their mean derivative is similar enough.
    In general, these two steps are fail-safes to prevent the algorithm from connecting surfaces on loose connections due to small gaps between edges.

    In an effort to achieve the desired outcome, attempts were made to implement morphologic operations, erosion and dilation @MorphologicalOperator. 
    However, these attempts proved unsuccessful, as they resulted in the algorithm's inability to detect thin roof parts.
    In summary, regardless of the minimal size of the erosion kernel, it inevitably proved to be excessively radical, resulting in a significant number of pixels and especially entire surfaces being lost.
    Given the small image size, too many components of the roof, small or thin sections, were being filtered out during the process.
    Therefore, this approach was found to be unsatisfactory, since detection of all components is a requirement. 
    Consequently, the current method of pixel categorization was developed, as it enables greater control over the behavior of the pixels.
    
    In this step, surfaces that are only connected through thin parts are subdivided into multiple smaller surfaces.
    In such instances, the algorithm will attempt to reconnect the resulting sub-components.
    In order to accomplish the aforementioned objective, the algorithm first calculates the mean derivative of each surface.
    Subsequently, the method identifies surfaces that were previously part of the same surface and are sufficiently proximate in their mean derivatives. These surfaces are then reconnected accordingly.
    The mean derivative has been identified as the most robust method for this purpose, as the average derivative is more susceptible to outlier values.

    Consequently, this results in the introduction of a new parameter: the absolute minimum difference between the mean derivative of two surfaces to be connected.
    In instances where the threshold is set at an too-high level, correctly separated surfaces are erroneously reconnected.
    Conversely, when the threshold is set too low, surfaces are split into multiple surfaces, a phenomenon that predominantly occurs on smaller surfaces.
    The threshold value is established as absolute, given the substantiated finding that percentage-based thresholds induce a false bias against flat roof structures and excessively prompt the algorithm to merge high derivative surfaces.

    The linking step implements a failsafe that verifies spatial connectivity following the merging of two surfaces. This is due to the fact that a simple combination of derivatives does not guarantee this, particularly when larger surfaces are fragmented into numerous components.
    This issue primarily originates from improper parameterization in the Canny algorithm outlined in @section:canny. 
    This challenge was addressed regardless.

    This step, in general, only serves as a minor improvement and does not alter the outcome of the algorithm in a significant way.
    Consequently, no comprehensive analysis or enhancement will be conducted on it, as preliminary experiments have demonstrated that an absolute reconnection threshold of 35 performs adequately overall.
    Errors resulting from erroneous surface connections will be addressed through a negative impact on the segmentation evaluation in @section:scoring.
    
    Subsequent research endeavors may seek to enhance the present methodology, particularly given its focus on reconnecting surfaces that have been separated during the current procedure. Additionally, it could be worthwhile to investigate the potential for interconnectedness among adjacent surfaces in a comprehensive manner.
    Consequently, this would necessitate a more sophisticated approach, as the algorithm would be required to verify all adjacent surfaces, as opposed to solely those that were divided.
    Additionally, the prevailing algorithm does not incorporate failsafes against the occurrence of two adjacent surfaces having the same mean derivative, yet being at different height levels, signifying that they are, in fact, not connected.

    ==== Results
    @fig:surface_separation shows how the surfaces are created and how the separation and linking steps influence the outcome.
    Initially, three larger surfaces were merged despite the presence of a clearly defined edge between them; however, this edge was only partially identified but not fully connected.
    Consequently, the algorithm divided them into three smaller surfaces.
    Subsequently, reconnecting the surfaces was attempted; however, the mean derivative of the surfaces was found to be too different, rigthfully not resulting in reconnection.
    Nonetheless, the algorithm successfully reconnected numerous small surfaces that had been divided due to their inherent thinness.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
      figure(image("../figures/surface_separation/1.png"), caption: [
        Surface Growth.
      ]), <fig:surface_separation:a>,
      figure(image("../figures/surface_separation/2.png"), caption: [
        Separation.
      ]), <fig:surface_separation:b>,
      figure(image("../figures/surface_separation/3.png"), caption: [
        Re-linking.
      ]), <fig:surface_separation:c>,
      caption: [
        Surface Growth, Separation and Re-linking.
      ],
      label: <fig:surface_separation>,
    )

    ==== Base Area Filtering <section:surfaces:filtering>
    At this stage, the algorithm identifies all surfaces within the image, extending beyond the base area of the structure.
    This could be regarded as a non-issue, as it is theoretically possible to consider all extant surfaces in the image.
    Nonetheless, the decision was made to exclusively examine and inspect the surfaces within the house's base area. 
    Consequently, this necessitated the implementation of a filtration process to remove external surfaces.

    Given that the algorithm has already obtained the clipped pixel from the edge detection pipeline, it was determined that it was feasible to utilize this information in this particular step.
    The implementation of the surface growth algorithm on the clipped pixel image produces a set of surfaces that approximately define the areas of the image.
    By this set of segments, the house area can be identified.
    Due to practicality, the algorithm will simply check with overlap regarding the mask from the input data. However, a more sophisticated approach independent of the input data could be developed in future work.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      box(figure(image("../figures/scoring_algorithm/found_mistake/2.png")), clip: true, width: 100%, inset: (left: -5.4in, right: -2.8in, top: -0.3in)),
      box(figure(image("../figures/scoring_algorithm/found_mistake/3.png")), clip: true, width: 100%, inset: (left: -5.4in, right: -2.8in, top: -0.3in)),
      caption: [
        Base Area Detection with (left) and without (right) Refinement.
      ],
      label: <fig:scores:founderror>,
    )

    In the final algorithm for this section, the base area filtering will be executed prior to separation and re-linking, as the filtration of surfaces before these steps exerts a significant influence on the resulting execution time.
    Given the potential abundance of small surfaces in the external environment, the efficiency of the algorithm is contingent upon the optimization of its calculation process.
    In addition, preliminary experimentation has demonstrated that employing the refinement steps intended for normal surfaces on the base area surfaces yields no more positive results than negative ones.
    A notable distinction emerges in the application of refinement to the detected base area, as illustrated in @fig:scores:founderror. 
    The application of refinement to the thin segment on the left would result in the erroneous filtration of that segment.
    While it demonstrates increased resilience against minor variations in the house outlines, it exhibits reduced robustness in other aspects.
    The prevailing assumption was that if an insufficient amount of clipping for detecting the building's outline was applied, remediation was possible by simply increasing the clipping percentage.
    While this approach is not without its limitations, as it likely results in more clipping than necessary and is not entirely robust, these aspects will not be addressed in this work.
    This is partially due to the fact that the base area detection will be addressed by @section:replace_clipping_by_sam, which will replace this specific part of the algorithm by using SAM on the nDSM data to find the base area.

    #figure(
      image("../data/6/1/v1/surfaces.png", width: 100%),
      caption: [
        Intermediary steps of the Surface Generation.
      ],
    ) <fig:surfaces_pipeline>

    As illustrated by @fig:surfaces_pipeline, the surface steps from one of the image test runs are displayed.
    The detection of the house area is evident, as is the filtration of numerous small surfaces in the external environment.
    The necessity to overestimate the clipping percentage can be determined by the presence of clipped values throughout the house, suggesting a higher than necessary value, as actual information on the roof may be lost.
    However, the algorithm appears to be functioning adequately during initial experimentation on a diverse set of houses.

    === Scoring System for Evaluation <section:scoring>
    In the preceding tests, the quality of the majority of surfaces could be adequately assessed by manual observation for initial parameter tuning and theory validation.
    However, as the general structure was being established, a greater necessity for objective evaluation criteria emerged.
    The methodology under consideration should possess the capacity to evaluate the quality of surfaces based on the following criteria:
    - The surface's values must be coherent, meaning that the surface's values should be similar throughout its entirety.
      While it is acknowledged that this value will not attain a perfect score due to the aforementioned noise and imperfection of input data, it is expected to be maximized.
      Preliminary experimental findings suggest that the majority of surfaces appear to exhibit a derivative that is not perfectly continuous across all values.
      The objective of this criterion is to guarantee that the algorithm does not undersegment the data.
      In the event that the algorithm merges surfaces incorrectly, the resultant derivative values will be inconsistent, which will consequently lead to a lower score here.
    - The surface area is a critical consideration in this analysis.
      In order to address the issue of the algorithm undersegmenting surfaces, it is proposed that a reward be allocated for surfaces of greater size.
      It is imperative that the augmentation of score through the implementation of this reward does not violate the established first criteria of coherence.
    
    ==== Experimental Usage of DBSCAN

    An initial attempt was made to use the Density-Based Spatial Clustering of Applications with Noise (DBSCAN) algorithm @dbscan1.
    This algorithm is employed to detect clusters in data, a common task in machine learning.
    The interpretation of surface derivatives as a point cloud renders them applicable to this algorithm.

    The algorithm's capacity to discern anomalies may be adequate; however, its precision is not sufficiently reliable for incorporation into the scoring system or for general evaluation purposes.
    The implementation of the algorithm is contingent upon two parameters: the epsilon and the minimum sample number. These parameters delineate the requisite spatial density of a cluster.
    Additional experimentation with the algorithms parameter may be feasible; however, preliminary tests have demonstrated that the quality of the algorithms is contingent on this parameter. Achieving satisfactory results, nevertheless, appears to be impracticable.
    
    To illustrate the problematic application, @fig:dbscan presents illustrative results of the DBSCAN algorithm on three disparate surfaces, yielding suboptimal outcomes in each instance.
    Note that the label -1 is given to all points considered noise @dbscan2.
    The surface utilized in @fig:dbscan:a is comprised of three surfaces that have been erroneously merged.
    Nonetheless, the algorithm proved incapable of identifying this particular instance and instead labeled 17 different surfaces. 
    Notably, it failed to recognize the two outer surfaces as coherent entities and erroneously merged the inner surface with the edges surrounding the other two.
    
    In contrast, the other two examples are each a single, coherent surface.
    In @fig:dbscan:b, a perfectly normal surface only affected by minor noise inside the derivative values, the entire surface is identified as noise, with the actual noise for some reason being given multiple labels.
    @fig:dbscan:c contains a significant amount of noise, resulting in no surface detection at all, labeling everything as noise.

    For purposes of illustration, consider the adjustment of parameters. 
    To that end, @fig:dbscan:b would require a higher minimum sample number, thereby enabling the algorithms to disregard inconsistencies in the data. 
    Conversely, @fig:dbscan:c would necessitate a lower value to detect anything, under the assumption that epsilon remains constant in both cases.

    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../figures/dbscan_test/1.png"), caption: [
        Falsely merged surfaces.
      ]), <fig:dbscan:a>,
      figure(image("../figures/dbscan_test/2.png"), caption: [
        Little noise.
      ]), <fig:dbscan:b>,
      figure(image("../figures/dbscan_test/3.png"), caption: [
        Much noise.
      ]), <fig:dbscan:c>,
      caption: [
        Execution of DBSCAN on three different surfaces.
      ],
      label: <fig:dbscan>,
    )

    The necessity of precise parametrization in each instance constitutes a significant challenge, as this section aims to assess the validity of any surface with a high degree of success.
    Consequently, as this approach necessitates an evaluation of the scoring parameter, its applicability in this context is considered limited.
    While the method could potentially be applied for surface evaluation or even segmentation in general, it will not be pursued further in this study.

    ==== Plateau Algorithm for individual Surfaces
    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    To achieve this objective, a tailored algorithm was developed to assess the quality of the results obtained. 
    This algorithm functions independently of the specific input data, thereby eliminating the need for adjustments.
    This process is achieved through the analysis of the derivatives of each surface in all directions, including the x, y, and magnitude values.
    In each of these directions, the algorithm seeks to identify regions exhibiting approximately constant or close values. 
    These regions will henceforth be designated as plateaus, as visualizing the data reveals the ideal representation of a perfect surface.
    The final result will be a score between 0 and 1 for each surface, which itself is an equal-valued combination of the three directions.

    A failsafe has been incorporated to address the issue of surfaces exhibiting characteristics indicative of undersegmentation, such as the presence of multiple plateaus indicating a merge of at least two surfaces into a single one.
    At present, the penalty is excessively severe in that it results in the surfaces' score being reduced to zero in such cases.
    Empirical observation has demonstrated that this step is necessary due to the existence of weak edges and the necessity to detect them.
    However, it should be noted that this algorithm is inherently incapable of detecting surfaces that are connected and exhibit close derivatives.
    Addressing this issue would necessitate the identification of jumps in the height value graph of the surface, a topic that will not be further explored in this study.

    The implementation of the plateau algorithm is not entirely independent of parameter.
    The subject of this discussion is the minimum plateau relevance and the plateau tolerance.
    The minimum plateau relevance is defined as the percentage of numbers that must be in a points vicinity to be considered a plateau.
    In this particular instance, the term "vicinity" is defined by the plateau tolerance, which delineates the absolute permissible discrepancy in values between two points until they are no longer regarded as being within the same plateau.
    However, all subsequent scores will be calculated by setting the parameter to 0.1 and 15, respectively. 
    The rationale behind this selection is that these values demonstrated notable success in identifying plateaus during the testing phase.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    The following implementation illustrates the calculation of individual scores for each surface in relation to the derivative values and their interpretation.
    This excludes all filtering and optimization steps, such as the initial sorting of derivative values.
    Additionally, this does not address the method by which the surfaces are subsequently integrated to generate the segmentation score in its entirety.

    ```python
    def scoring(...):
      relevance = params.minimum_plateau_relevance
      tolerance = params.plateau_tolerance

      # Find Center Points counting as plateaus pillar
      def find_plateau(values):
        counts = {}
        for value in values:
          rounded = round(value / tolerance) * tolerance
          counts[rounded] = counts.get(rounded, 0) + 1
        plateau_values = []
        for rounded_value, count in counts.items():
          if count / len(values) >= relevance:
            plateau_values.append(rounded)
        return plateau_values

      # Get score from given plateaus values
      def calculate(values, plateaus):
        if not plateaus:
          return 0

        # Check if all plateau values are within tolerance distance
        has_one_plateau = all(
          abs(plateaus[j] - plateaus[j - 1]) <= tolerance
          for j in range(1, len(plateaus))
        )

        if has_one_plateau:
          num_plateau_pixels = sum(
            1 for value in values
            if any(abs(value - pillar) <= tolerance for pillar in plateaus)
          )
          return num_plateau_pixels / len(values) if values else 0
        else:
          return 0

      # ...

      # Calculate for each direction
      combined_score = 0
      for derivative in [x, y, magnitude]:
        plateaus = find_plateau(derivative)
        score = calculate(derivative, plateaus)
        combined_score += scores

      return combined score /= 3
    ```

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      box(figure(image("../data/6/1/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -11.1in)),
      box(figure(image("../data/6/4/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -9.9in, top: -2.5in)),
      box(figure(image("../data/6/4/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -12.35in)),
      caption: [
        Results of the Plateau Algorithm.
      ],
      label: <fig:plateau>,
    )

    @fig:plateau presents exemplary extracts from the graphs representing the algorithm's results.
    The first example illustrates a flawless surface, which is identified as such by the algorithm.
    It is important to acknowledge that the graphs are not normalized, which results in an apparent unevenness that does not accurately reflect the underlying data.
    The values ranging from 80 to 100 are regarded as sufficiently proximate to be classified as a single, cohesive plateau.

    The second example row demonstrates a surface that persists of two merged surfaces, which the algorithm detects in the x and magnitude direction. 
    This is visually quite good and can be confirmed as two distinct plateaus in the data.

    The third row illustrates a regrettable scenario in which both the x and y directions exhibit a single dominant plateau, a phenomenon that is accurately reflected in the scores.
    However, the magnitude direction indicates a single elevated jump in values, resulting in the identification of two plateaus rather than one. 
    Consequently, the score is rendered null.
    This is unfortunate and likely indicative of the fragility of the magnitude values, which renders them unsuitable for use in the score calculation.
    However, given the algorithm's equitable allocation of values to all three directions, this issue is mitigated, as the remaining two directions retain the capacity to generate a satisfactory score.
    
    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/surface_scoring/7.png")),
      figure(image("../figures/scoring_algorithm/surface_scoring/6.png")),
      figure(image("../figures/scoring_algorithm/surface_scoring/5.png")),
      caption: [
        Plateau Algorithm on a Spire Roof.
      ],
      label: <fig:scores2>,
    )

    The performance of the algorithm on a more challenging roof shape, namely a spire, is demonstrated in @fig:scores2.
    The algorithm exhibits clear indications of encountering challenges in processing the roof geometry, as evidenced by the coherent nature of the derivative values, which are monotonically increasing. 
    This inherent property is characteristic of roof types of this nature.
    Nevertheless, the data indicates that the functionality of the algorithms remains consistent with the expected operational parameters.
    The erroneous segmentation of the data results in the formation of distinct plateaus, which are subsequently identified by the algorithm. 
    These plateaus manifest as multiple green areas on the surface that are wrongfully merged together.
    The data indicates that, in these cases, the magnitude value is significantly impactful. 
    On a spire or rounded surfaces in general, the multiplication of the x and y directions generates a coherent plateau which is mathematically provable.

    However, this data gives rise to inquiries that could potentially inform enhancements to the system's algorithms.
    Presently, the equitable distribution of points among the three directions results in the algorithm's minimal penalization of the two plateaus in the x direction, despite the fact that, in certain instances, this may serve as sufficient evidence of an erroneous surface segmentation.
    It may be necessary to consider the implementation of a more stringent penalty for instances where values are absent. However, it is important to note that imposing a penalty of zero for the entire surface area may prove to be overly severe.
    
    ==== Segmentation Scoring
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    $ S_"pos" &= (sum_(i=0)^n ((S_x (i) + S_y (i) + S_m (i)) / 3 * abs(i)²)) / (sum_(i=0)^n (abs(i)²)) \
      S_"neg" &= (sum_(i=0)^n abs(i)) / N \
      S &= S_"pos" * p + S_"neg" * (1 - p) $ <formula:score>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]

    Following the individual scoring of the surfaces, the generated scores must be aggregated to create a final score that evaluates the segmentation of the roof in its entirety.
    The preliminary implementation of this process entails the combination of each individual surface score.
    The surface's score is subject to manipulation by multiplication of two components: the result score of the plateau algorithm and the surface's squared size.
    As previously stated, the algorithm calculates this in order to assign greater rewards to surfaces of greater size in comparison to smaller surfaces.
    Therefore, a surface with a large surface area and optimal values will achieve a higher score than two smaller surfaces with perfect values.
    However, a small surface with imperfect values will likely demonstrate superior performance in comparison to a large surface characterized by numerous incoherent values.

    #figure(
      box(figure(image("../figures/scoring_algorithm/segmentation_scoring/1.png")), clip: true, width: 100%, inset: (bottom: -2.6in, left: -0.3in)),
      caption: [
        Example Scores for different Clipping Values.
      ],
    ) <fig:score:segmentation>

    As demonstrated by @fig:score:segmentation, this scoring method produces overall acceptible results.
    The performance of the algorithm was satisfactory when executed with the provided parameter values, evidenced by the high scores obtained.
    However, it has become evident that the algorithm requires augmentation through the incorporation of a negative score. 
    This is attributable to the fact that the algorithm does not take into account the filtration of an excessively large area of the roof or even entire segments.
    As illustrated, this effect occurs when the clipping value is increased because the current algorithm is unaffected by a reduction in overall surface area.






    When a parameter change is made, which results in a good surface being completely filtered out, the score of the algorithm should be lowered accordingly.
    For this purpose the algorithm splits the score into a positive and a negative score.
    In addition to the positive score the negative score is calculated by the percentage of the combined area of the filtered surfaces to the total area of the roof, which is given in the input data.
    This way the algorithm aquires the ability to detect missing house areas, which are not covered by the generated surfaces.
    While the exact roof structure inside the input data may be unusable due to their missing quality, the area covered by the house is good enough for usage in the algorithm.
    With having both a positive and a negative score ranging from 0 to 1, which both having 1 as the optimal result, the final score may be a weighted sum of those two.
    For now, an equal weighting is deemed sufficient as lower weighing of the negative score could lead to the algorithm not detecting missing areas as good as it should.
    From this, the resulting formula can be seen in @formula:score, where p currently is as said 0.5 and N is the total number of pixels belonging to the house according to the data given.
    

    In @fig:scores:squareornot the difference between using the square of Safethe surface size and not using it is shown.
    Looking at the positive score, it becomes clear that it does indeed have the intended effect, as in @fig:scores:squareornot:a the bigger surface is rewarded more than the smaller one, while in @fig:scores:squareornot:b the smaller surface is rewarded more than the bigger one which in turn leads to the clearly worse segmentation on the right having the same positive score, even though the noise edges inside surfaces are clearly visible and divide big surfaces into multiple smaller ones.
    On the other hand this example also shows the working effect of the negative score, as the more an image is to the right the lower the resulting score, due to the fact that the right images have a lot of area falsely filtered out.
    Also the absolute values of positive scores are not comparible between the two approaches, since the squared scores have a higher variety of values, since there denominator becomes bigger.
    This in turn leads to the negative score having different influence on the resulting score, which may lead to a therorical need for adjustments.
    In reality this is only a minor influence to the overall performance.
    Continuing foreward, the algorithm will use the squaring method, as the results are more satisfying.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/segmentation_scoring/2.png"), caption: [
        Using the square of the surface size
      ]), <fig:scores:squareornot:a>,
      figure(image("../figures/scoring_algorithm/segmentation_scoring/3.png"), caption: [
        Not using the square of the surface size
      ]), <fig:scores:squareornot:b>,
      caption: [
        Example comparison betweens using or not using the square of the surface size.
      ],
      label: <fig:scores:squareornot>,
    )
  ]
}