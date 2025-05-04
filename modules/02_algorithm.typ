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
    // TODO

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

    In the final algorithm for this section, the base area filtering will be executed prior to separation and re-linking, as the filtration of surfaces before these steps exerts a significant influence on the resulting execution time.
    Given the potential abundance of small surfaces in the external environment, the efficiency of the algorithm is contingent upon the optimization of its calculation process.
    In addition, preliminary experimentation has demonstrated that employing the refinement steps intended for normal surfaces on the base area surfaces yields no more positive results than negative ones.
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
    /*

    While for the earlier tests the quality of most surfaces was sufficiently evaluatbable by human eyes, a greater need for objective criterion arose.
    This function should be able to evaluate the quality of the surfaces based on the following criteria:
    - The coherence of the surface's values, meaning that optimaly the surface should have a similar value over the whole surface.
      While realistically this value will not achieve a perfect score due to the aforementioned noise and imperfection of input data, it should be as high as possible.
      In experiments it becomes clears that almost no surface has a perfect derivative across all values or even if it does, it is also possible that an actually bigger surface go split too much by the algorithm.
    - The size of the surface. 
      To address the algorithm cutting down surfaces too much, I propose to add a reward for bigger surfaces.
      // TODO: valentina mentioned oversegmentation here
      This should be done in a way that the reward is not too big, as it could lead to the algorithm just merging all surfaces into one big surface.
      A bigger surface which is not coherent should be penalized accordingly.
    
    Also note that for better visual clarity most figures in this section or rather from now on use magnitude colouring.
    What this means is that the colour of a surface is determined by the mean magnitude calculated from x and y direction.
    While most algorithms do not use the magnitude for calculation, for example the edge detection pipeline using x and y directions distinctly, this is a still a good way for simple visualization of the data.
    While two magnitudes of defintely disjunct roof tiles can be the same, which can be confusing to look at, it is still preferebly to random colouring of surfaces, as random colouring across multiple images in a series of experiments creates unnecessary hardship when evaluating the data.

    ==== Experimental Usage of DBSCAN

    // TODO: DBSCAN source and why it theoretically could have been used
    Using spatial information by for example using labeling through DBSCAN failed in almost every case due to the data inconsistency inside even perfect surfaces.
    The algorithm may be able to detect that something wrong, but not consistently enough to be used in the scoring system or in generell serious evaluation.
    Further experimentation with the algorithms parameter of epsilon and minimum sample number may be possible, and quick tests have shown that the algorithms quality can highly vary depending on these, but achieving satisfying results seems unfeesable.
    For demonstration @fig:dbscan shows examplary results of the DBSCAN algorithm three different surfaces with subpar results.
    While @fig:dbscan:a would in reality be three surfaces, @fig:dbscan:b and @fig:dbscan:c are actually one surface each. 
    As an example to adjust parameters, @fig:dbscan:b would need a higher minimum sample number, so that the algorithms ignores inconsistencies in the data, whilest @fig:dbscan:c would actually need a lower value to detect anything, assuming no change to epsilon.
    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../figures/dbscan_test/1.png"), caption: [
        Three falsely merged surfaces.
      ]), <fig:dbscan:a>,
      figure(image("../figures/dbscan_test/2.png"), caption: [
        Surface with little noise.
      ]), <fig:dbscan:b>,
      figure(image("../figures/dbscan_test/3.png"), caption: [
        Surface with a lot of noise.
      ]), <fig:dbscan:c>,
      caption: [
        One iteration of the DBSCAN results. Clustering here was only done on derivative data not on spatial information, since the algorithm would otherwise only detect the fact that, of course, it is spatially connected. The algorothm detected 17, 3 and 0 Cluster respectively, showing too high dependency on the parameter.
      ],
      label: <fig:dbscan>,
    )

    ==== Plateau Algorithm

    For this purpose a custom algorithm was developed which evaluates the quality of a surface.
    It does this by analyzing each surfaces derivative values, in each direction meaning x, y and their combination.
    For each direction the algorithm tries to generate plateaus, which are areas with approximately constant derivative values, or at least no sudden or big changes in the derivative value.
    // TODO: better explanation or find a formula for each surface
    By simpe multiplication of a surfaces size and the number of coherent values, the algorithm can generate a score for each surface.
    As required, this score naturally lies between 0 and 1, where 1 is the best possible score.
    To realize the aforementioned reward for bigger surfaces, the algorithm multiplies the score with the size of the surface squared.
    This way a perfect big surface will outscore two perfect small surfaces, but a perfect small surface will outscore a big surface with a lot of incoherent values.

    Also a failsafe was added which harshly penalizes a surface which has more than one plateau, meaning that the surface shows signes of being a two surfaces being merged into one.
    For now this penalty simply makes each of these wrong surfaces have a score of 0.
    Practice has shown that this is neccessary due to the fact that the existence of weak edges can lead to multiple surfaces being merged into one.
    If this happens, the algorithm can by itself not detect two same-derivative-surfaces being connected through another surface, as no spatial information is used in the algorithm.

    @fig:scores shows the results of the algorithm on different houses.
    Sorting the derivative values belonging to detected plateaus not only serves as a good visualisation, but also removes the spatial correletaion between the values as was the case in the DBSCAN algorithm.
    The algorithm is able to detect good surfaces, as shown in @fig:scores:a, but also has problems with surfaces which have a high variance of values, as shown in @fig:scores:b.
    On partly incorrect surfaces like @fig:scores:c, the algorithm does not fail completely, but gives an acceptible result.
    The problem is, that the derivative values on the roof top edges simply do not match the surface's values, so by algorithm it is encoured to split those values into a non-real surface spanning the edge.
    Currently, this is not a big problem, as it only minorly effects the results, as in generel they do not need to be perfect, but merely good enough to be used as a vague basis for further analysis.
    Due to this, it can be argued that errors in @fig:scores:b and @fig:scores:c are not too severe, as the surfaces are either small enough too not invalidate the whole segmentation of the house or are hard to interpret for a human as well.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/surface_scoring/1.png")),
      figure(image("../figures/scoring_algorithm/surface_scoring/4.png"), caption: [
        Two good surfaces.
      ]), <fig:scores:a>,
      figure(image("../figures/scoring_algorithm/surface_scoring/3.png"), caption: [
        Small surface with high variance of values.
      ]), <fig:scores:b>,
      figure(image("../figures/scoring_algorithm/surface_scoring/2.png"), caption: [
        Hard to interpret surface.
      ]), <fig:scores:c>,
      caption: [
        Example results of the plateau algorithm with values belonging to detected plateaus coloured in green.
      ],
      label: <fig:scores>,
    )

    Adjusting the visual output by adding the calculated scores directly into the image and running the algorithm on an objectively harder to segment roof shape, the results are shown in @fig:scores2.
    The algorithm shows clear signs of struggling with the roof shape, as the derivative values are not as coherent as on the previous surfaces, not due to noise, but due to the rounded shape.
    This data however shows, that the algorithms works as expected.
    The wrong segmentation creates clear plateaus in the data, which are perfectly detected by the algorithm by having multiple green areas on the surface which are not connected.
    However, even though for now this algorithm will be used in further experiments, this data creates questions, to which the answers could lead to  further improvements on the algorithms scoring system:
    - By hand or other means creating a perfect segmentation on the rounded surface may lead to interesting insights on the perfect result, which in turn,  may generate a better insight on how to improve the algorithm.
    - Currently the even scoring between the three directions leads to the algorithm only minorly punishing the two plateaus in the x direction, even though in this specific case it is enough proof that the surface was segmented wrong. 
      Maybe a harsher punishment for having 0 values is neccessary, but in turn for exampe making the entire surfaces score 0 would probably be too harsh.
    - Trying to create a method to add the spatial correlation, which was removed by sorting the values, may lead to methods of better scoring round roofs.
      The only problem with this is that this would also lead to the algorithm being susceptible to outliers in the middle of surfaces again, which currently are not a problem, since they are ignored outliers on the graphs extrema.
      They currently do not effect functionality but only very slightly decreasing the score, which is worth the improvement on the algorithm's robustness against noisy data.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/surface_scoring/7.png")),
      figure(image("../figures/scoring_algorithm/surface_scoring/6.png")),
      figure(image("../figures/scoring_algorithm/surface_scoring/5.png")),
      caption: [
        Excerpt from the next iteration of the scoring algorithm calculated on a spire roof, meaning a complicated roof shape for the algorithm due to varying derivative values on single surfaces.
      ],
      label: <fig:scores2>,
    )

    Following the individual scoring of the surfaces, the generated scores need to be put together to create a final score which evaluates the segmentation of the roof as a whole.
    This is done by the aforementioned even scoring between the three directions, which is then multiplied by the sum of the squares of the surface sizes.
    @fig:score:segmentation shows the results of the scoring algorithm on an example house.
    Here, It quickly becomes visible why the algorithm needs to be expanded by a negative score.
    Run on some example values on the input parameters, the algorithm performs quite well, which as expected results in high scores.

    #figure(
      image("../figures/scoring_algorithm/segmentation_scoring/1.png", width: 100%),
      caption: [
        The result of each step inside the surface pipeline. The parameter used here are 50% minimum overlap for the Best Surfaces as well as the Filtered Surfaces.
      ],
    ) <fig:score:segmentation>

    However, the algorithm at this point did not take into account that values which are too high clip the image in a way that the surface overlapping filters out too much area of the roof.
    When a parameter change is made, which results in a good surface being completely filtered out, the score of the algorithm should be lower.
    For this purpose the algorithm splits the score into a positive and a negative score.
    In addition to the positive score the negative score is calculated by the percentage of the combined area of the filtered surfaces to the total area of the roof, which is given in the input data.
    This way the algorithm aquires the ability to detect missing house areas, which are not covered by the generated surfaces.
    While the exact roof structure inside the input data may be unusable due to their missing quality, the area covered by the house is good enough for usage in the algorithm.
    With having both a positive and a negative score ranging from 0 to 1, which both having 1 as the optimal result, the final score may be a weighted sum of those two.
    For now, an equal weighting is deemed sufficient as lower weighing of the negative score could lead to the algorithm not detecting missing areas as good as it should.
    From this, the resulting formula can be seen in @formula:score, where p currently is as said 0.5 and N is the total number of pixels belonging to the house according to the data given.
    $ S_"pos" &= (sum_(i=0)^n ((S_x (i) + S_y (i) + S_m (i)) / 3 * abs(i)²)) / (sum_(i=0)^n (abs(i)²)) \
      S_"neg" &= (sum_(i=0)^n abs(i)) / N \
      S &= S_"pos" * p + S_"neg" * (1 - p) $ <formula:score>

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

    Looking at the results of this scoring led to the invastigation on why the results show some minor errors.
    @fig:scores:founderror shows the intermediary steps on how the roof got segmented.
    Here it becomes visible, that it is inconvenient to use the refinement used in the surface pipeline when generating the surfaces on the clipped values to generate the house's base area to filter from.
    Accordingly, changing this in the code leads to @fig:scores:founderror:c, which does indeed show a better segmentation.
    However, it also becomes clear that this change only minimaly effects overall performance, as the "All Surfaces" column clearly shows the edge detection having problems on the thin roof part due to it having bad alignment with the pictures axes.
    While this also only minorly influences the result, it may be worth noting that this simple change increases the score by 1%.
    This again may not seem much but may later on prove to be crucial between deciding between segmentations.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/found_mistake/1.png"), caption: [
        Edge Detection Pipeline.
      ]), <fig:scores:founderror:a>,
      figure(image("../figures/scoring_algorithm/found_mistake/2.png"), caption: [
        Surface generation using refinement of the clipped surfaces.
      ]), <fig:scores:founderror:b>,
      figure(image("../figures/scoring_algorithm/found_mistake/3.png"), caption: [
        Surface generation without refinement.
      ]), <fig:scores:founderror:c>,
      caption: [
        Comparison between using and not using the refinement of the clipped surfaces.
      ],
      label: <fig:scores:founderror>,
    )
    */
  ]
}