#import "@preview/subpar:0.2.0"

#let ndsm_analysis(abr) = {
  text(lang:"en")[
    = Creation of reliable Input Prompts <section:ndsm_analysis>
    As a need for more reliable input prompts emerged, this section will discuss the process of programming a custom pipeline to create segmentations.
    It is proposed that these segmentations will prove more reliable in prompting #abr("SAM"), and therefore should result in superior overall outputs.
    This will provide a foundation for further analysis to ascertain whether #abr("SAM") is capable of solving the given problem of complex building roof segmentation when given improved input prompts.

    The basis of this section is the hypothesis that the correct input points result in improved segmentations by #abr("SAM").
    This encompasses enhanced segmentations in terms of structural integrity, a consideration that was not previously a given when utilising the input mask.
    It is essential that each segment is more accurate, and the total number of segmentations should increase to a minimum of the number of segments in the original image.
    It is hypothesised that this will resolve the issue of surfaces of a smaller size not being able to be predicted, as the absence of an individual prompt for them was the issue.

    The following oberservations and assumptions are made in this section:
    - In comparison to the #abr("nDSM") data, the original #abr("RGB") pictures contain almost no relevant information.
      The #abr("nDSM") data containing the buildings house data is fully capable of serving the relevant information which a segmentation algorithm needs for successful identification of the roof's structure.
      The following sections will therefore not make use of the #abr("RGB") data but solely focus on height information.
    - Using the #abr("nDSM") data however entails having the need to be able to handle its multiple flaws.
      For example, most surfaces will not have perfectly smooth derivative data due to seemingly random instabilities inside the given data.
      The height values of a structurally normal  roof segment should in theory be piecewise representable as a continuous function, meaning that the derivative values should be similar or rather constant across the whole surface, which is however disrupted by such abnormalities.
      Therefore, the algorithm will be forced to handle such errors and ensure they do not invalidate its output.
      Invalidation hereby means that such occurrences do not lead to major miscategorisations of segments.

    The present chapter is composed of three sections.
    @section:algorithm will encompass a comprehensive discussion of the algorithmic components that facilitate the generation of custom segmentation for any given house.
    In this section, the discussion will center on the introduction of hyperparameters that have demonstrated potential in facilitating the algorithm's adaptability to variable scenarios.
    Therefore, the section introduces a scoring algorithm that aims to evaluate the quality of a given segmentation. This evaluation process serves to determine whether parameter adjustment is necessary.

    Consequently, @section:truth_compare will generate some ground truth examples to ascertain the system's reliability and the effectiveness of the scoring system.
    These metrics will be employed to derive an objective score for statistical analysis and comparison.
    
    Lastly, @section:ablation of this chapter will then return to said parameter and perform an ablation study on the actual effect of these, intended for the purpose of achieving a better understanding and filtering out those parameters with minor effect so that they will not be considered in further calculations on unseen data.

    == Algorithmic Identification of Roof Structures <section:algorithm>
    In the following sections, the #abr("nDSM") data will be utilised to calculate derivatives, process the data, and consequently detect edges inside the image.
    The derivatives are generally distinguished between x and y directions.
    The utilisation of combined values, expressed as magnitudes, is not a viable approach. 
    In the context of mathematics, the operation of multiplying "x" by "-y" is equivalent to the inverse operation of multiplying "-x" by "y."
    However, in practical applications, it is essential to differentiate between these two cases.
    This predicament stems from the problem of opposing roofs having mirrored signs, which is most problematic on axis-aligned houses, where the resulting magnitude of opposing roofs can be identical.
    Consequently, the algorithm may interpret these surfaces as identical, despite substantial disparities in their individual x and y values.

    - Initially, derivatives are constructed using appropriate algorithms to generate data that is more conducive to analysis than the raw #abr("nDSM") data.
      In this case, the derivatives will be separated into two distinct components: x and y directions. 
      Each of these components will be managed independently.
    - Subsequently, the algorithm implements a series of transformations, including logarithmic scaling, clipping, and Gaussian blurring. 
      The objective of these transformations is to enhance contrast and remove noise, thereby facilitating improved algorithmic analysis.
    - Subsequently, the Canny Edge Detection algorithm will be implemented to identify edges in both directions, with each direction processed individually.
      Subsequently, the edges originating from the x and y directions are combined through the application of logical operations. 
      This process ultimately yields the final, combined edges.
    - In summary, the last sub-section will delineate the combined steps constituting the entire edge detection pipeline together.

    At the beginning and after every step, the algorithm will normalise the values.
    This will be the range $[-255, 255]$ at first, to represent positive and negative derivatives, and later $[0, 255]$ to be in valid range for the Canny Edge Detection algorithm.
    This creates better comparability between different input data and will serve to increase the contrast of the values.

    This process of normalisation may result in a particular side effect.
    Given the absence of assurance that the quantity of positive values is equivalent to the quantity of negative values, the algorithm may potentially displace the neutral value for flat surfaces away from zero.
    This phenomenon can be illustrated by examining @fig:algorithm:zero_moving, in which the neutral value is shifted to the right.
    As the contrast of the data is enhanced, the perceptibility of the effect increases. 
    This phenomenon is illustrated on the right side of the figure, where the red colouration of the flat ground is more pronounced in comparison to the left side.
    To address this issue, the algorithm would need to implement a complete separation of positive and negative values during each normalisation.
    However, this effect has only been observed on rare occasions, and even in cases where it has been observed, its impact on the algorithm is not proven to be negative.
    The effect of this appears to be primarily visual, as the algorithm does not take into account the location of the zero value within the value spectrum.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      box(figure(image("../data/6/5/v2/edges.png")), clip: true, width: 100%, inset: (bottom: -1.0in, left: -1.5in, right: -3.8in)),
      caption: [
        Visualisation of normalisation moving the zero value
      ],
      label: <fig:algorithm:zero_moving>,
    )
    
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
    In essence, the functionality of both operators is equivalent; the only discrepancy lies in the kernel utilised, as illustrated by @formula:sobel and @formula:scharr @ScharrOperator @SobelOperator @derivative_sobel1.

    A more conventional way of calculating the derivative is to interpret each row and column as a function defining the values x and then to use the standard mathematical approach demonstrated by @formula:gradient. 
    Here, the derivative is calculated by taking the difference between two adjacent pixels and dividing it by the distance between them. 
    Since the distance between two pixels is always 1, the parameter h can be omitted. 
    While this is theoretically the most mathematically accurate way of calculating the derivative, it is also the most computationally expensive, since the kernel convolution can be optimised quite efficiently. 
    Nevertheless, it is definitely a promising approach and will be included in the algorithm for later evaluation. 
    A fourth method, called the sliding window approach, mimics the novel approach of calculating the gradient without the mathematical correctness of the division by $2h$.
    This approach was utilised as a form of exploratory experimentation, in combination with the other methods, to assess if it could be effective.

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

      # Initial normalisation
      n = cv2.normalise(entry['ndsm'], None, 0, 255, cv2.NORM_MINMAX)

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
    This subsection will focus on one such chosen method, namely applying a logarithmic transformation to the input data.
    It is generally accepted that higher contrast is beneficial for visual confirmation. 
    Additionally, it is presumed that higher contrast enhances the overall performance of the algorithm.
    At the very least, the visual appeal of the intermediate derivative image is greatly improved, making most values and edges more distinguishable.
    The strong effect of this can be seen in @fig:algorithm:log, where not only a visual distinction is possible only after scaling, but also the distribution plot clearly reflecting better utilisation of the value spectrum.

    The analysis of the derivative data indicates that, subsequent to normalisation, the majority of the data is comprised of values predominantly concentrated around zero. 
    This is attributable to the presence of extreme outliers within the dataset, resulting in a substantially uneven distribution of values.
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
        Impact of applying the logarithm on derivative data
      ],
      label: <fig:algorithm:log>,
    )

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    The following implementation stores the sign of each value first, because the logarithm is not defined for negative values.
    Therefore, after applying the logarithm to the absolute derivative values, they are normalised and multiplied by the original sign.
    In this way, the logarithm can be applied while preserving the original sign of the derivative values, i.e. without losing the differentiability between positive and negative values.

    ```python
    def edge_detection(...):
      # ... other steps

      ####### STEP 2 : LOGARITHMIC SCALING
      # Store the sign of the original derivatives
      sign = np.sign(derivative)

      # Apply log1p to the absolute values
      log = np.log1p(np.abs(derivative))

      # Normalise the logarithmic values
      derivative = cv2.normalise(log, None, 0, 255, cv2.NORM_MINMAX)

      # Reapply the original sign
      derivative = derivative * sign

      # ... other steps
    ```

    ==== Clipping extreme Values <section:clipping>

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    A visual analysis of the individual steps during the initial setup of this pipeline has revealed some statistical constants across the different data sets.
    This includes the observation that the edge surrounding the house consistently exhibits the most extreme derivative values.
    The following hypothesis is formulated: the precise difference between such extreme derivatives is inconsequential.
    Consequently, the clipping of those values followed by normalisation has been shown to positively enhance the contrast of the image, thereby facilitating the evaluation process for the algorithm without the loss of crucial information (Smith, 2019).
    The validity of this hypothesis will be demonstrated in the @section:ablation:clipping, in which it will be demonstrated that clipping can indeed be beneficial.

    In this context, setting the clipping percentage to 10 percent entails the reduction of the highest and lowest 10 percent values.
    It is evident that, given the normalisation of the values preceding this step, the derivative values between $[-255, 255]$, in this example, will be set to $[-230, 230]$. Consequently, all values that fall outside this range will be set to the new extrema.

    The hypothesis was formulated that interpreting the actually clipped values as edges and subsequently executing the surface generation steps on them could function as a mask for base area detection, as will be discussed in @section:surfaces:filtering.
    The direct effect of this is shown in @fig:algorithm:clipping, which shows the difference between applying 0 and 7 percent clipping.
    While no clipping shows very low distinguishable values, the shape of the roof becomes visible after the clipping is applied.
    Inside the value graph, the hills representing the individual segments become visible.
    It should be noted that in the example shown no normalisation was applied, but the general effect is not affected by this.
    Said theory of base area detection can also be seen in the visualisation of the clipped values in the bottom column of the graphs.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      box(figure(image("../figures/clipping/0.png"), caption: [0%]), clip: true, width: 100%, inset: (bottom: 0.1in, left: -4.3in, right: -4.3in)),
      box(figure(image("../figures/clipping/7.png"), caption: [7%]), clip: true, width: 100%, inset: (bottom: 0.1in, left: -4.3in, right: -4.3in)),
      caption: [
        Comparison between clipping percentages
      ],
      show-sub-caption: (num, it) => {
        [#it.body]
      },
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
    A two-dimensional kernel approximating a Gaussian distribution is used to apply a convolution to the image, thereby blurring the image @Gauss1.
    Note that due to the small size of the image, this blurring leads to a loss of detail, which results in a loss of detail and, consequently, may result in an inability to detect thin roof parts.
    The position of blurring inside the overarching edge detection pipeline was determined after a series of preliminary experiments.
    For instance, the application of blurring to the raw #abr("nDSM") data demonstrated a comparatively diminished level of overall success.

    The implementation of this introduces the parameters of kernel size and sigma value @Gauss2.
    The sigma value defines the standard deviation of the Gaussian function, which in turn determines the amount of blur applied to the image.
    However, the influence of these parameters will not be explored extensively, and only 3x3 and 5x5 kernels will be tested, as well as whether noise reduction has the desired positive influence.
    The sigma values are not explicitly set, so the algorithm automatically calculates them to be $#sym.sigma ≈0.8$ and $#sym.sigma≈1.1$ for 3x3 and 5x5 kernels respectively.
    @formula:gaussian_kernel shows the mathematically correct Gaussian 3x3 kernel.
    It is noteworthy that the OpenCV kernel deviates marginally at the four edge values due to the implementation of corrections, which results in a kernel sum that approaches closer to 1 to reduce errors.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    ```python
    class BlurringMethod(Enum):
        NONE = 0
        SMALL = 1
        MEDIUM = 2

    def edge_detection(...):
      # ... other steps

      clipped = cv2.normalise(clipped, None, -255, 255, cv2.NORM_MINMAX)

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
    The usage of the Canny algorithm enables the flexible adaptation of the system to the unique characteristics and requirements of each individual house.
    The underlying rationale for this phenomenon stems from the implementation of a complex calculation method that utilises two parameters, lower and upper thresholding, to filter out edges based on gradient magnitude @Canny2.

    It should be noted that alternative edge-detection algorithms could be considered.
    Algorithms of a simpler nature are based on the gradient value between the x and y directions of the image.
    Nonetheless, such filters—for instance, the Sobel filter—are often found to be inadequate, particularly in noisy environments @Sobel2.
    A substantial number of comparisons between Sobel and Canny detection exist.
    The Sobel filter's most notable strength is its simplicity, which is advantageous in applications where rapid execution is paramount @Sobel1.
    However, the temporal efficiency of the process is not a primary concern; instead, the emphasis is placed on the quality of the results obtained.
    Canny's superior performance is attributable to its capacity for enhanced parameter tuning, a feature that is particularly advantageous in achieving more precise edge detection @Sobel3.

    The determination of the optimal values for the lower and upper threshold will necessitate a process of experimentation and will vary between houses.
    There have been suggestions of dynamically calculating the threshold values based on the gradient's median value @Canny3. 
    However, this was not implemented due to initial tests not yielding promising results.
    Conversely, the algorithm will utilise dynamic percentage thresholds.
    It is important to acknowledge that this approach will essentially replicate the utilisation of absolute values directly, as the data undergoes normalisation to fall within the range of 0 to 255 prior to the application of the Canny algorithm.

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    The Canny algorithm is restricted to positive integer inputs.
    Therefore, the range of values must undergo transformation from $[-255, 255]$ to $[0, 255]$, entailing the halving of the value range.
    Consequently, there is a marginal loss of information, as the range of positive and negative values is reduced by half each.
    For instance, the values 255 and 254 are combined into a single value of 255 after the transformation process, becoming indistinguishable.
    However, this informational reduction is presumed to exert a negligible effect on the outcomes.

    The threshold values are designated as the lower and upper percentiles of the normalised image.
    While they are set at equal intervals in this instance for the sake of simplicity, they can be adjusted to allow for uneven percentiles in the future, should preliminary results prove unsatisfactory.
    For instance, setting the percentage to 35 will result in a threshold of $[89, 179]$, a representation that nearly perfectly aligns with the novel approach of setting the upper threshold at double the lower threshold.
    #pagebreak()

    ```python
    def edge_detection(...):
      lower = params.canny_values[0]
      upper = params.canny_values[1]

      # ... other steps

      ####### STEP 5 : EDGE DETECTION
      normalised = cv2.normalise(
          blurred, None, 0, 255, cv2.NORM_MINMAX, cv2.CV_8U
      )

      lower_threshold = int(np.percentile(normalised, lower))
      upper_threshold = int(np.percentile(normalised, upper))
      edges = cv2.Canny(normalised, lower_threshold, upper_threshold)

      # ... other steps
    ```
    
    ==== Results <section:edges:results>
    #figure(
      image("../figures/edge detection/pipeline1.png", width: 100%),
      caption: [
        Edge Detection Pipeline
      ],
    ) <fig:algorithm:edges:pipeline>

    @fig:algorithm:edges:pipeline demonstrates the full pipeline that was utilised for the edge detection step.
    The derivatives for each step are assigned a colour, ranging from blue to red, with blue signifying negative values and red denoting positive ones.
    Given that these are divided into the x and y directions, this colouration method is adequate.

    It should be noted that the parameters were not optimised for this specific image, but are exclusively utilised for illustrative purposes here.
    For instance, given the absence of substantial outliers in the image, which would typically serve to diminish contrast, it is plausible that the clipping value was set at an excessively high value. 
    This hypothesis is substantiated by observation of the distribution charts.
    The impact of blurring is discernible, as the surface colouration exhibits a more polished and smooth appearance subsequent to the application of this technique.

    === Surface Growth <section:surface_growth>

    ==== Initial Creation of Surfaces
    The subsequent generation of surfaces is enabled by the utilisation of the edges that have been computed in the edge detection pipeline.
    Initially, all edge pixels must be filtered out, leaving only non-edge pixels for consideration.
    The initial step involves the designation of one of these pixels as a surface. 
    Subsequently, an iterative process is employed to append all adjacent pixels from the list of non-edges.
    This process is repeated until no connected pixels remain, at which point the current surface has grown to occupy the entirety of its available space.
    In the event that there are non-edge pixels remaining that have not yet been assigned to any surface, it is necessary to assign one of them as a new surface and to begin appending all adjacent pixels once more.
    This process is repeated until all pixels of the image are assigned.
    There is no need for parameterisation, nor are there any edge cases that must be considered.

    ==== Separation and Relinking
    Next, the algorithm takes the generated surfaces and splits them on pixels that do not belong to edges but are adjacent to an edge, before attempting to reconnect such separated surfaces if their mean derivative is similar enough.
    In general, these two steps are fail-safes to prevent the algorithm from connecting surfaces on loose connections due to small gaps between edges.

    In an effort to achieve the desired outcome, attempts were made to implement morphologic operations, erosion and dilation @MorphologicalOperator. 
    However, these attempts proved unsuccessful, as they resulted in the algorithm's inability to detect thin roof parts.
    In summary, regardless of the minimal size of the erosion kernel, it inevitably proved to be excessively radical, resulting in a significant number of pixels and especially entire surfaces being lost.
    Given the small image size, too many components of the roof, small or thin sections, were being filtered out during the process.
    Therefore, this approach was found to be unsatisfactory, since detection of all components is a requirement. 
    Consequently, the current method of pixel categorisation was developed, as it enables greater control over the behavior of the pixels.
    
    In this step, surfaces that are only connected through thin parts are subdivided into multiple smaller surfaces.
    In such instances, the algorithm will attempt to reconnect the resulting sub-components.
    To accomplish said reconnection, the algorithm first calculates the mean derivative of each surface.
    Subsequently, the method identifies surfaces that were previously part of the same surface and are sufficiently proximate in their mean derivatives.
    The mean derivative has been identified as the most robust method for this purpose, as the average derivative is more susceptible to outlier values.

    Consequently, this results in the introduction of a new parameter: the absolute minimum difference between the mean derivative of two surfaces to be connected.
    In instances where the threshold is set at a too-high level, correctly separated surfaces are erroneously reconnected.
    Conversely, when the threshold is set too low, surfaces are split into multiple surfaces, a phenomenon that predominantly occurs on smaller surfaces.
    The threshold value is established as absolute, given the substantiated finding that percentage-based thresholds induce a false bias against flat roof structures and excessively prompt the algorithm to merge high derivative surfaces.

    The linking step implements a failsafe that verifies spatial connectivity following the merging of two surfaces. This is due to the fact that a simple combination of derivatives does not guarantee this, particularly when larger surfaces are fragmented into numerous components.
    This issue primarily originates from improper parameterisation in the Canny algorithm outlined in @section:canny. 
    This challenge was addressed regardless.

    This step, in general, only serves as a minor improvement and does not alter the outcome of the algorithm in a significant way.
    Consequently, no comprehensive analysis or enhancement will be conducted on it, as preliminary experiments have demonstrated that an absolute reconnection threshold of 35 performs adequately overall.
    Errors resulting from erroneous surface connections will be addressed through a negative impact on the segmentation evaluation in @section:scoring.
    
    Subsequent research endeavors may seek to enhance the present methodology, particularly given its focus on reconnecting surfaces that have been separated during the current procedure. Additionally, it could be worthwhile to investigate the potential for interconnectedness among adjacent surfaces in a comprehensive manner.
    Consequently, this would necessitate a more sophisticated approach, as the algorithm would be required to verify all adjacent surfaces, as opposed to solely those that were divided.
    Additionally, the prevailing algorithm does not incorporate failsafes against the occurrence of two adjacent surfaces having the same mean derivative, yet being at different height levels, signifying that they are, in fact, not connected.

    ==== Results
    @fig:surface_separation illustrates the three-step process of surface generation: the initial surface growth phase, the separation phase, and the re-linking step.
    The provided example shows how the separation and linking steps influence the outcome.
    Initially, three larger surfaces were merged despite the presence of a clearly defined edge between them; however, this edge was only partially identified but not fully connected.
    The algorithm was able to accurately divide the surfaces into three smaller surfaces.
    Subsequently, an attempt was made to reconnect the surfaces; however, the mean derivative of the surfaces was found to be too different, rightly resulting in not reconnecting them.
    Notwithstanding, the algorithm effectively reconnected numerous small surfaces that had been divided due to their inherent thinness.

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
        Steps of the surface generation
      ],
      show-sub-caption: (num, it) => {
        [#it.body]
      },
      label: <fig:surface_separation>,
    )

    ==== Base Area Filtering <section:surfaces:filtering>
    At this stage, the algorithm identifies all surfaces within the image, including those outside the base area of the structure.
    This could be regarded as a non-issue, as it is theoretically possible to consider all extant surfaces in the image.
    Nonetheless, the decision was made to exclusively examine and inspect the surfaces within the house's base area. 
    Consequently, this necessitated the implementation of a filtration process to remove external surfaces.

    Given that the algorithm has already obtained the clipped pixels from the edge detection pipeline, it was determined that it was feasible to utilise this information in this particular step.
    The implementation of the surface growth algorithm on the clipped pixels image produces a set of surfaces that approximately define the areas of the image.
    By this set of segments, the house area can be identified.
    Due to practicality, the algorithm will simply check with overlap regarding the mask from the input data. However, a more sophisticated approach independent of the input data could be developed in future work.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      box(figure(image("../figures/scoring_algorithm/found_mistake/2.png")), clip: true, width: 100%, inset: (left: -5.4in, right: -2.8in, top: -0.3in)),
      box(figure(image("../figures/scoring_algorithm/found_mistake/3.png")), clip: true, width: 100%, inset: (left: -5.4in, right: -2.8in, top: -0.3in)),
      caption: [
        Base Area Detection with (left) and without (right) Refinement
      ],
      label: <fig:scores:founderror>,
    )

    In the final algorithm for this section, the base area filtering will be executed prior to separation and re-linking, as the filtration of surfaces before these steps exerts a significant influence on the resulting execution time.
    Given the potential abundance of small surfaces in the external environment, the efficiency of the algorithm is contingent upon the optimisation of its calculation process.
    Furthermore, preliminary experimentation has demonstrated that employing the refinement steps intended for normal surfaces on the base area surfaces has positive effects as well as negative ones.
    A notable distinction emerges in the application of refinement to the detected base area, as illustrated in @fig:scores:founderror. 
    The application of refinement to the thin segment on the left would result in the erroneous filtration of that segment.
    While it demonstrates increased resilience against minor variations in the house outlines, it exhibits reduced robustness in other aspects.
    The prevailing assumption was that if an insufficient amount of clipping for detecting the building's outline was applied, remediation was possible by simply increasing the clipping percentage.
    While this approach is not without its limitations, as it likely results in more clipping than necessary and is not entirely robust, these aspects will not be addressed in this work.
    This is partially due to the fact that the base area detection will be addressed in @section:replace_clipping_by_sam, which will replace this specific part of the algorithm by using #abr("SAM") on the #abr("nDSM") data to find the base area.

    #figure(
      image("../data/6/1/v1/surfaces.png", width: 100%),
      caption: [
        Intermediary steps of the surface generation
      ],
    ) <fig:surfaces_pipeline>

    As illustrated by @fig:surfaces_pipeline, the surface steps from one of the image test runs are displayed.
    The detection of the house area is evident, as is the filtration of numerous small surfaces in the external environment.
    The necessity to overestimate the clipping percentage can be determined by the presence of clipped values throughout the house, suggesting a higher than necessary value, as actual information on the roof may be lost.
    However, the algorithm functions adequately well during initial experimentation on a diverse set of houses. 

    === Scoring System <section:scoring>
    In the preceding tests, the quality of the majority of surfaces could be adequately assessed by manual observation for initial parameter tuning and theory validation.
    However, as the general structure was being established, a greater necessity for objective evaluation criteria emerged.
    The methodology under consideration should possess the capacity to evaluate the quality of surfaces based on the following criteria:
    - The values in a surface must be coherent, meaning that they should be similar throughout its entirety.
      While it is acknowledged that this value will not attain a perfect score due to the aforementioned noise and imperfection of input data, it is expected to be maximised.
      Preliminary experimental findings suggest that the majority of surfaces appear to exhibit a derivative that is not perfectly continuous across all values.
      The objective of this criterion is to guarantee that the algorithm does not undersegment the data.
      In the event that the algorithm merges surfaces incorrectly, the resultant derivative values will be inconsistent, which will consequently lead to a lower score.
    - The surface area is a critical consideration in this analysis.
      In order to address the issue of the algorithm undersegmenting surfaces, it is proposed that a reward be allocated for surfaces of greater size.
      It is imperative that the augmentation of score through the implementation of this reward does not violate the established first criteria of coherence.
    
    ==== Experimental Usage of DBSCAN
    An initial attempt was made to utilise the #abr("DBSCAN") algorithm @dbscan1.
    This algorithm is employed to detect coherent clusters in data, a common task in machine learning.
    The interpretation of surface derivatives as a point cloud renders them applicable to this algorithm, in that the derivative values should exhibit a certain degree of spatial coherence.

    The algorithm's capacity to discern anomalies may be adequate; however, its precision is not sufficiently reliable for incorporation into the scoring system or for general evaluation purposes.
    The implementation of the algorithm is contingent upon two parameters: epsilon and the minimum sample number. 
    These parameters specify the necessary spatial density of a cluster.
    It is conceivable that further experimentation with the algorithms parameter may yield favorable outcomes; nevertheless, preliminary tests have demonstrated a strong correlation between the quality of the algorithms and the values of this parameter. 
    It appears that achieving satisfactory results is an unfeasible task.
    
    @fig:dbscan presents illustrative results of the #abr("DBSCAN") algorithm on three disparate surfaces, yielding suboptimal outcomes in each instance.
    Note that the label -1 is given to all points considered noise @dbscan2.
    The surface utilised in @fig:dbscan:a is comprised of three surfaces that have been erroneously merged.
    Nonetheless, the algorithm proved incapable of identifying this particular instance and instead labeled 17 different surfaces. 
    Notably, it failed to recognise the two outer surfaces as coherent entities and erroneously merged the inner surface with the edges surrounding the other two.
    
    In contrast, the other two examples are each a single, coherent surface.
    In @fig:dbscan:b, a perfectly normal surface affected by minor noise is shown, however, the entire surface is labeled as noise by the algorithm, with the actual noise being given labels.
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
        Execution of #abr("DBSCAN")
      ],
      label: <fig:dbscan>,
    )

    The necessity of precise parametrisation in each instance constitutes a significant challenge, as this section aims to assess the validity of any surface with a high degree of success.
    Consequently, as this approach necessitates an evaluation of the scoring parameter, its applicability in this context is considered limited.
    While the method could potentially be applied for surface evaluation or even segmentation in general, it will not be pursued further in this study.

    ==== Plateau Algorithm for individual Surfaces
    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    To achieve this objective, a tailored algorithm was developed to assess the quality of the results obtained. 
    This algorithm functions independently of the specific input data, thereby eliminating the need for adjustments.
    This process is achieved through the analysis of the derivatives of each surface in all directions, including the x, y, and magnitude values.
    In each of these directions, the algorithm seeks to identify regions exhibiting approximately constant or close values. 
    These regions will henceforth be designated as plateaus, as visualising the data reveals the ideal representation of a perfect surface.
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
    This excludes all filtering and optimisation steps, such as the initial sorting of derivative values.
    Additionally, this does not address the method by which the surfaces are subsequently integrated to generate the segmentation score in its entirety.

    #pagebreak()
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
    @fig:plateau presents exemplary extracts from the graphs representing the algorithm's results.
    In the first row, an example is illustrated which shows a flawless surface, which is identified as such by the algorithm.
    The three calculated scores are 98%, 97%, and 96%, respectively, for x, y, and magnitude direction.
    In all three directions, there is a single plateau that extends across the majority of the surface.
    It is important to acknowledge that the graphs are not normalised, which results in an apparent unevenness that does not accurately reflect the underlying data.
    The values ranging from 80 to 100 are regarded as sufficiently proximate to be classified as a single, cohesive plateau.

    #subpar.grid(
      columns: 1,
      gutter: 1mm,
      box(figure(image("../data/6/1/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -11.1in)),
      box(figure(image("../data/6/4/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -9.9in, top: -2.5in)),
      box(figure(image("../data/6/4/v1/plateau.png")), clip: true, width: 100%, inset: (bottom: -12.35in)),
      caption: [
        Results of the plateau algorithm
      ],
      label: <fig:plateau>,
    )

    The second example row illustrates a surface that persists of two merged surfaces, which the algorithm detects in the x and magnitude directions. 
    The surface score resulting from the individual scores of 0%, 93%, and 0% is 31%, which is indicative of poor quality.
    One could argue for the invalidation of the entire score, but further analysis of this hypothesis will not be pursued.
    The presence of two distinct plateaus in the data is also evident in the graphs.

    The third row illustrates a regretable scenario in which both the x and y directions exhibit a single dominant plateau. 
    This is accurately reflected in the scores being 94%, 87%, and 0%, respectively.
    The graph of the magnitude direction exhibits a pronounced jump in values, leading to the identification of two plateaus rather than one. 
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
        Plateau algorithm on a spire roof
      ],
      label: <fig:scores2>,
    )

    The performance of the algorithm on a more challenging roof shape, namely a spire, is demonstrated in @fig:scores2.
    The three rows presented here are an excerpt from an experiment conducted on a spire roof.
    The algorithm displays evident indications of encountering challenges in processing the roof geometry, as demonstrated by the coherent nature of the derivative values, which are monotonically increasing.
    This inherent property is characteristic of roof types of this nature.
    Nevertheless, the data indicates that the functionality of the algorithms remains consistent with the expected operational parameters.
    The erroneous segmentation of the data results in the formation of distinct plateaus, which are subsequently identified by the algorithm. 
    These plateaus manifest as multiple green areas on the surface that are wrongfully merged together.
    The data indicates that, in these cases, the magnitude value is significantly impactful. 
    On a spire or rounded surfaces in general, the multiplication of the x and y directions generates a coherent plateau which is mathematically provable.

    Presently, the equitable distribution of points among the three directions results in the algorithm's minimal penalisation of the two plateaus in the x direction, despite the fact that, in certain instances, this may serve as sufficient evidence of an erroneous surface segmentation.
    It may be necessary to consider the implementation of a more stringent penalty for instances where values are absent. However, it is important to note that imposing a penalty of zero for the entire surface area may prove to be overly severe.
    
    ==== Segmentation Scoring
    #heading(depth: 5, numbering: none, bookmarked: false)[Formula]
    S = Set of all surfaces

    $p_i$ = Plateau score for surface i

    $A_i$ = Size of surface i

    N = Size of Base Area

    $ #sym.Phi _"pos" &= (sum_(i #sym.in 0) (p_i * A_i²)) / (sum_(i #sym.in 0) (A_i²)) \
      \
      #sym.Phi _"neg" &= (sum_(i #sym.in 0) (A_i²)) / N \
      \
      #sym.Phi _"res" &= (#sym.Phi _"pos" + #sym.Phi _"neg") / 2 $ <formula:segment_score>

    #heading(depth: 5, numbering: none, bookmarked: false)[Explanation]
    Following the individual scoring of the surfaces, the generated scores must be aggregated to create a final score that evaluates the segmentation of the roof in its entirety.
    The preliminary implementation of this process entails the combination of each individual surface score.
    The surface's score is calculated by multiplying the result score of the plateau algorithm by the surface's squared size.
    As previously stated, the algorithm calculates this in order to assign greater rewards to surfaces of greater size in comparison to smaller surfaces.
    Therefore, a surface with a large surface area and optimal values will achieve a higher score than two smaller surfaces with perfect values.
    However, a small surface with imperfect values will likely demonstrate superior performance in comparison to a large surface characterised by numerous incoherent values.
    This calculation is denoted as $#sym.Phi _"pos"$ in @formula:segment_score.

    #figure(
      box(figure(image("../figures/scoring_algorithm/segmentation_scoring/1.png")), clip: true, width: 100%, inset: (bottom: -2.6in, left: -0.3in)),
      caption: [
        Scores for different clipping values
      ],
    ) <fig:score:segmentation>

    As demonstrated by @fig:score:segmentation, this scoring method produces overall acceptable results.
    The performance of the algorithm was satisfactory when executed with the provided parameter values, evidenced by the high scores obtained.
    However, it has become evident that the algorithm requires augmentation through the incorporation of a negative score. 
    This is attributable to the fact that the algorithm does not take into account the filtration of an excessively large area of the roof or even entire segments.
    As illustrated, this effect occurs when the clipping value is increased because the current algorithm is unaffected by a reduction in overall surface area.

    A segmentation that results in the complete removal of a surface should cause the score of the algorithm to be reduced, as this process decreases the percentage of the base area that is covered.
    For this purpose, in addition to the positive score a negative score has been introduced, denoted by $#sym.Phi _"neg"$.
    The base area is currently derived from the input data, but it has the potential to be calculated dynamically if a more robust method for base area detection is identified.
    While the mask contained within the input data may be unsuitable for more specific analysis due to missing quality, the area covered by the house is adequate for utilisation in this algorithm.

    In this manner, the algorithm is able to detect missing house areas.
    Given that both scores are on a scale from 0 to 1, with 1 representing the optimal result, the final score can be calculated as a weighted sum of these two scores.
    A reduction in the negative score's weighting could potentially result in the algorithm's failure to detect missing areas.
    An increase in its weighing may result in the underestimation of the true quality of the segment in question.
    Therefore, the final score is calculated as the arithmetic mean of the two scores, with equal weight assigned to each.

    #heading(depth: 5, numbering: none, bookmarked: false)[Results]
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
        Results for scoring based on segmentation
      ],
      label: <fig:scores:squareornot>,
    )

    @fig:scores:squareornot shows the results for the segmentation scoring.
    Two examples are provided to illustrate the distinction between utilising the square of the surface area and using the surface area directly, without any bias toward larger surfaces.
    Upon examination of the positive score, it becomes evident that the intended effect is indeed being achieved. 
    As illustrated in @fig:scores:squareornot:a, the larger surface is given greater value than the smaller one.
    @fig:scores:squareornot:b prioritises smaller surfaces over larger segments. 
    This is due to the fact that the two smaller surfaces possess differing mean derivatives. Consequently, there is an indirect increase in the change for each value to be near the current mean.
    Consequently, the segmentation on the right, which is visibly suboptimal, exhibits an analogous positive score despite the discernible noise edges that divide large surfaces into multiple smaller ones.
    
    @fig:scores:squareornot also demonstrates the operational dynamics of the negative score, whereby the score undergoes a reduction in proportion to the extent of clipping, as an increasing number of segments are systematically filtered out.
    The impact of the negative score on the result score is evident, as it offers a more accurate reflection of the quality of the segmentation compared to the previous example before its implementation.
  ]
}