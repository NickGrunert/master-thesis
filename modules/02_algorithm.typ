#import "@preview/subpar:0.2.0"

#let ndsm_analysis() = {
  text(lang:"en")[
    = Creation of reliable Input Prompts

    == Identification of Roof Structures through Analysis of nDSM Data
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




    /*
    @section:edge_detection will create derivations and use the Canny Algorithms for edge detection.
    An edge between segments can highly change in how obvious it is in the data.
    Henceforth, the algorithm will need to adjust on a case to case basis using parameters, which will be discussed for each sub-section individually.
    In turn, this leads to the need of creating a scoring algorithm in @section:scoring.
    This system will be able to analyze the result of a run and re-run it with adjusted parameters, or rather will be used to create an analysis on how the parameters actually effect the result and which ranges of them make sense.
    */


    === Edge Detection using the Canny Algorithm <section:edge_detection>

    ==== Calculating the Derivative
    
    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    //TODO
    @ScharrOperator @SobelOperator

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    While all of the following implementations do not distinguish between the x and y directions, in this single section it is necessary due to implementation details where they need to be handled separately.

    ```python
    class DerivativeMethod(Enum):
      SOBEL = 0
      SLIDING = 1
      GRADIENT = 2
      SCHARR = 3

    def edge_detection(...):
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

    ==== Applying Logarithmic Scaling

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    // TODO

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
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


    /*
    Using the Logarithm on the original, but normalized, nDSM Image data will help to enhance the contrast of the image. This will not only make the image more visually appealing but also easier to interpret. 
    @fig:algorithm:log shows the difference when applying the Logarithm directly after calculating the derivative.
    It is observable that the image which contains logarithmic normalization has less extreme maxima and minima, which makes it easier to interpret the image, due to the smaller values being more prominent, leading to a more balanced image in intensity.
    In the Image not using logarithmic scaling, most colours become very pale whilest only the extreme values on for example the edges of the house become intensively coloured, leading to the fact, that the image becomes hard to interpret by human eyes when trying to evaluate or validate the calculated data.
    The results of both are of quite different quality, which is due to the parameter of 'clipped percentage’ and input parameter for the Canny Edge Detection algorithm. 
    It appears that they could be changed in such a way that both images are much more similar in quality, but this is not researched in depth until after @section:scoring, when better experimentation is possible due to the scoring system.
    For now, further experiments will continue to use the logarithmic normalization, as it is a simple and effective way to enhance the contrast of the image, which in turn results in a wider or better scope for parameter tuning.
    */

    ==== Clipping extreme Values

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    // TODO

    #heading(depth: 5, numbering: none, bookmarked: false)[Implementation]
    ```python
    def edge_detection(...):
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

    ==== Gaussian Blurring

    #heading(depth: 5, numbering: none, bookmarked: false)[Theory]
    Overall, the derivative is very noisy due to inconsistencies in the input height information.
    To address this issue, the algorithm will use Gaussian smoothing for noise reduction.
    A 2-dimensional kernel approximating a Gaussian is used to apply a convolution to the image.
    This blurs the entire image @Gauss1.

    Using the OpenCV Gaussian blur implementation @Gauss2 introduces several new possible parameters, the kernel size and sigma values.
    The sigma values define the standard deviation of the Gaussian function, which in turn determines the amount of blur applied to the image.
    However, the influence of these parameters will not be explored extensively, and only 3x3 and 5x5 kernels will be tested, as well as whether noise reduction has the desired positive influence at all.
    The sigma values are not explicitly set, so the algorithm automatically calculates them to be $≈0.8$ and $≈1.1$ for 3x3 and 5x5 kernels respectively.

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

    ==== Canny Edge Detection

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
    ```python
    def edge_detection(...):
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
    





    /*
    #figure(
      image("../figures/apply_log/Result.png", width: 100%),
      caption: [
        Comparison between using the Logarithm on the original nDSM Image data and the original nDSM Image data without prior adjustments.
      ],
    ) <fig:algorithm:log>

    @fig:edp:pipeline shows the full pipeline used for the edge detection.
    For now, the pipeline is kept simple, as the main goal is to create a basis for further experiments.
    The derivatives are distinguished between x and y directions, as using the combined values in the form of magnitude creates error.
    This problems stem from the fact that opposing roofs can have mirrored signs in their derivative values, which in turn leads to the algorithm interpreting them as the same surface even though their x and y values may highly differ.

    #figure(
      image("../figures/edge detection/pipeline1.png", width: 100%),
      caption: [
        Later Iteration of the Edge Detection Pipeline using found Improvements in calculation and visualisation.
      ],
    ) <fig:edp:pipeline>

    For better comparisons accross multiple roofs as well as better generalization, between each step the data gets normalized.
    The pipeline starts with the calculation of the derivative of the nDSM data using the Sobel operator .
    Interestingely, visualizing the absolute values inside the bars plots shows the roof segments quite clearly, as the graph is a layering of the individual segments graphs.
    While the clipping which follows in the next step was introduced to improve the contrast in the values, we also apply logarithmic scaling to the output values of the derivative.
    //Further discussed in @section:log, this step is helpful in enhancing the contrast of the image, which in turn makes it easier to interpret.

    The next step is clipping the extreme values of the derivative data.
    This step may not be neccessary, but it adds nice and wanted improvements to the algorithm.
    These are, the most extreme values are ver likely to belong to the houses surface and are also very likely to outlier in regards to the rest of the data due to them simply logically being the highest changes in height.
    Therefore, clipping them has two effects:
    - The contrast in the values is increased, which makes the image easier to interpret.
      Not only visually but also for the algorithm, as the edges between roofs are more pronounced, which in turn leads to the algorithm being able to detect them more easily.
    - Using the clipped values gives a base for guessing the layout of the house.
      This is theoretically not neccessary, as the input data regarding the house's layout is given and of acceptable quality, but it may be useful for further experiments, as the algorithm may be able to detect missing areas of the house, which are not covered by the input data.
    However, this step creates a hyperparameter, which may need to be adjusted for each house, as the perfect percentage of clipped values may vary between houses.
    Using a value too high may lead to atrifacts inside the roof segments or even clipping entire surfaces together, using a value too low may lead to the algorithm not being able to detect house layout, meaning all surfaces will be filtered out, see @section:surface_growth.

    Disregarding the visual step back, @fig:clipping shows the difference between using and not using the clipping step.
    After clipping the data, the hills stemming from the roof segments are clearly visible.
    This however is not only visual for analysis but also helps the last edge detection step to find edges, since the absolute value of the inner edges is not overshadowed as much by the outer house edges.

    #subpar.grid(
      columns: 1,
      gutter: 2mm,
      figure(image("../figures/clipping/0.png"), caption: [
        Edge detection without clipping any values
      ]), <fig:clipping:a>,
      figure(image("../figures/clipping/7.png"), caption: [
        Edge detection clipping the highest and lowest 7% of values
      ]), <fig:clipping:b>,
      caption: [
        Edge Detection pipeline comparing the difference between no clipping and clipping 7% of maxima values.
      ],
      label: <fig:clipping>,
    )

    */






    === Surface Growth <section:surface_growth>

    Using the edges calculated in the edge detection pipeline, the algorithm is able to generate surfaces.
    This is done by simply letting all non-edge pixel #quote("grow") into all directions until only edge pixel are left and thereby all disjunct pixel structures represent a surface.
    While this in itself is relatively simple, @fig:surface_separation shows further improvements on this.
    Generally speaking, they are failsafes to prevent the algorithm from connecting surfaces on loose connections due to the edges having minor error.
    This is done by categorizing pixel touching edges as edge-pixel and separating surfaces which were only connecting through such.
    There were attempts to apply morpholigcal operations such as erosion and dilation @MorphologicalOperator to achieve this, but they were not successful, as they lead to the algorithm not being able to detect thin roof parts.
    Simply put, no matter how small for example the erosion kernel was, it would always lead to too many pixels being lost, meaning in turn small or thin parts of the roof would be filtered out, due to the small image size.
    As this was not satisfying, the current approach of pixel categorization was developed, as it also simplifies re-adding the removed pixel.
    
    However as this may lead to some real surfaces being split into multiple surfaces, a re-linking step is neccessary.
    For this, the algorithm calculates the mean derivative of each surface and connects surfaces which are close enough in their mean derivative.

    In turn, this leads to the introduction of the next parameter, the absolute minimum difference between the mean derivative of two surfaces to be connected, later simply called threshold.
    A threshold too high leads to rightly separated surfaces being falsely reconnected while a threshold too low, which is less problematic, leads to surfaces being split into multiple surfaces, which mostly happens on smaller surfaces.
    The threshold value thereby is absolute, as any form of percentage based threshold leads to a false bias against flat roof structures and too highly encoureages the algorithm to combine high derivative surfaces.

    Later on after @section:scoring, the algorithm may be able to dynamically determine the threshold, but for now it is set to a fixed value, which was found to be the best for the current data whilest admitting limitaions.
    Also, merging based on this value may not be the best approach at all.
    There may later on be a better approach by simply testing if the merging of two surfaces leads to a higher score, which should in theory lead to the same or rather better results.
    For now however, this remains theoretical and only a possibility for future improvements.

    In general this leads to good results, as the mean derivative of a surface should be quite similar across the whole surface whilest the derivative of two distinct surfaces should be different enough to not be connected.
    Two disjunct surfaces in question can only have about the same mean derivative if they are connected through another surface, which in turn should be detected by the algorithm, because after re-linking they are spatially not connected.
    On the other hand they could have the same mean if they have a gap in height between them, which should definitely be detected by the edge detection algorithm, or at least this concern would need to be addressed there.

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
      figure(image("../figures/surface_separation/4.png"), caption: [
        Magnitude.
      ]), <fig:surface_separation:d>,
      caption: [
        Example of what happens internly during the Surface Growth algorithm. 
        The effect of separation and re-linking are clearly visible here. 
        Since the previous edge detection algorithm did not supply sufficient edges, the splitting is neccessary to create a good segmentation, while the linking is neccessary to not split thin edges more than needed.
      ],
      label: <fig:surface_separation>,
    )

    The final step in the surface generation is the filtering of the surfaces.
    This is done by using the same Surface Grwoth algorithm to generate surfaces on the image of clipped pixels instead of the edge pixel.
    Albeit not perfect, this algorithms then takes the input data into account, in which the house's base layout is given.
    For simplification and to prevent the algorithm from filtering out too much, we take into account all clipped surfaces which have an overlap of at least 50% with the house's base layout.
    Then again we take this 50% parameter to filter out surfaces from the edge pixel images which do not have sufficient overlap.

    @fig:surfaces_pipeline shows the results of each step inside the surface pipeline.
    It is visible that this successfully filters out the non-house surfaces from the image as well as filters out many small surfaces which were generated due to the algorithm having certain problems near clipped pixels.
    An example for this is the visible imperfection near the red surface on ther lower right side of the house.

    The soft cyan and lime green clipped surfaces also show that indeed the algorithm can not just take the one best surfaces as balconies or similar structures need to be taking into account.

    #figure(
      image("../figures/surfaces/surfaces_pipeline.png", width: 100%),
      caption: [
        The result of each step inside the surface pipeline. The parameter used here are 50% minimum overlap for the Best Surfaces as well as the Filtered Surfaces.
      ],
    ) <fig:surfaces_pipeline>

    Additionaly the example house shown in the image shows that the algorithm without dynamic determination of parameters is not sufficient to solve the problem, because the house's small squared flat roof in the middle got merged with two outer roofs, which is plain wrong and should be detected and fixed.
    Respectively, the next section is about exactly that, the scoring system, which is neccessary to evaluate the quality of the generated surfaces.





    === Scoring System for Evaluation <section:scoring>

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
  ]
}