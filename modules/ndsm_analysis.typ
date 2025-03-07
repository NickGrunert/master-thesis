#import "@preview/subpar:0.2.0"

#let ndsm_analysis() = {
  text(lang:"en")[
    == Identification of Roof Structures through Analysis of nDSM Data
    Since we clarified the need for better ground truths to enable trustworthy prompting, this section will focus on algorithmic analysis of the nDSM data.
    The goal is the creation of a pipeline which hopefully delivers high quality roof segmentations in regards to finding out the vague shape, location and number of segments.
    In turn, this segmentation is to be used as a basis for input prompting when using SAM.
    This means this section does not neccessitate the creation of a perfect segmentation, but rather a sufficiently good enough segmentation to be used as a basis for further experiments.

    The following hypotheses will provide a basis for the development of the pipeline:
    - The nDSM data contains the house's height information relative to the ground.
      Using this, derivatives across the roof can be calculated and used to create viable segmentations.
    - There are multiple aspects about the optimal segmentation which may be hard to algorithmically approach.
      For example, the algorithm may have problems with surfaces which are not perfectly even in their derivative values.
      This is due to the fact that the algorithm may split the surface into multiple surfaces, as it detects a sudden change in the derivative values.
      This is a problem, as most roof surfaces are not perfectly even in their derivative values, for reasons as simple as the existence of roof tiles, that we would like to not regard solar panels as a separate surface or even round roof tiles.
      // TODO: Valentina said it is normal for nDSM to be piecewise not smooth due to interpolations in calculation...
    - Not only can the algorithm create segmentations, but it can also evaluate the quality of the generated surfaces.
      By analyzing the derivative values the surfaces can be evaluated using the coherence of the values.
      A roof segment's height sould always be piecewise representable as a continuous function, meaning that the derivative values should be similar or rather constant across the whole surface.
      While a rounded surface has continuous derivative values, a normal roof segment should hav constant derivative values across it.
      If the values of a surface are not coherent or continuous, it is an implication that it has an edge inside it, which in turn should be detected by the algorithm and the surface should be split into multiple surfaces.
      This score is then used to evaluate the quality of the surface, again, with the goal of representing the roof's structure as accurately as possible while acknowledging the limitations of this approach.

    === Edge Detection Pipeline

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
    The pipeline starts with the calculation of the derivative of the nDSM data using the Sobel operator @SobelOperator.
    Interestingely, visualizing the absolute values inside the bars plots shows the roof segments quite clearly, as the graph is a layering of the individual segments graphs.
    While the clipping which follows in the next step was introduced to improve the contrast in the values, we also apply logarithmic scaling to the output values of the derivative.
    Further discussed in @log, this step is helpful in enhancing the contrast of the image, which in turn makes it easier to interpret.

    The next step is clipping the extreme values of the derivative data.
    This step may not be neccessary, but it adds nice and wanted improvements to the algorithm.
    These are, the most extreme values are ver likely to belong to the houses surface and are also very likely to outlier in regards to the rest of the data due to them simply logically being the highest changes in height.
    Therefore, clipping them has two effects:
    - The contrast in the values is increased, which makes the image easier to interpret.
      Not only visually but also for the algorithm, as the edges between roofs are more pronounced, which in turn leads to the algorithm being able to detect them more easily.
    - Using the clipped values gives a base for guessing the layout of the house.
      This is theoretically not neccessary, as the input data regarding the house's layout is given and of acceptable quality, but it may be useful for further experiments, as the algorithm may be able to detect missing areas of the house, which are not covered by the input data.
    However, this step creates a hyperparameter, which may need to be adjusted for each house, as the perfect percentage of clipped values may vary between houses.
    Using a value too high may lead to atrifacts inside the roof segments or even clipping entire surfaces together, using a value too low may lead to the algorithm not being able to detect house layout, meaning all surfaces will be filtered out, see @surface_growth.

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

    A crucial step in the pipeline is applying Gaussian Blur @GaussianOperator to reduce noise through smoothing.
    This step is neccessary, as the derivative data is very noisy accross segments.
    Blurring the data leads to much improvement in the quality of the detected edges, as less noise inside a coherent surface is strong enough to be detected as an edge which in turn leads to the algorithm being less likely to split surfaces into multiple surfaces.
    However, it can be noted that due to the small size of the image this blurring leads to a loss of detail, meaning problems in the detection of thin roof parts.
    In earlier iterations of the algorithm, the blurring was done after shifting the data between 0 and 255, which the following edge detection algorithm uses.
    This, however small it was, lead to a minor loss of quality due to integer rounding so it was changed to be done before the shifting.

    The final step in the pipeline is the application of the Canny Edge Detection algorithm @CannyOperator.
    For now, due to short experiments showing the most promising results without further need for parameter tuning, the algorithm is used with lower and higher threshold being based on the 10th and 90th percentile of the blurred data, because this way of dynamic calculation leads to the best results on different houses, which simply put may not be satisfyingly segmentable with a fixed threshold.
    These found edges in x and y direction are then combined to create the final edge detection image, which is then used in the surface generation following in @surface_growth.

    === Surface Growth <surface_growth>

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

    Later on after @scoring, the algorithm may be able to dynamically determine the threshold, but for now it is set to a fixed value, which was found to be the best for the current data whilest admitting limitaions.
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

    === Objective Segmentation evaluation using a Scoring System <scoring>

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

    ==== Trying to use DBSCAN for surface evaluation

    // TODO: DBSCAN source and why it theoretically could have been used
    Using spatial information by for example using labeling through DBSCAN failed in almost every case due to the data inconsistency inside even perfect surfaces.
    The algorithm may be able to detect that something wrong, but not consistently enough to be used in the scoring system or in generell serious evaluation.
    Further experimentation with the algorithms parameter of epsilon and minimum sample number may be possible, and quick tests have shown that the algorithms quality can highly vary depending on these, but achieving satisfying results seems unfeesable.
    For demonstration @dbscanfig shows examplary results of the DBSCAN algorithm three different surfaces with subpar results.
    While @dbscanfig:a would in reality be three surfaces, @dbscanfig:b and @dbscanfig:c are actually one surface each. 
    As an example to adjust parameters, @dbscanfig:b would need a higher minimum sample number, so that the algorithms ignores inconsistencies in the data, whilest @dbscanfig:c would actually need a lower value to detect anything, assuming no change to epsilon.
    #subpar.grid(
      columns: 3,
      gutter: 2mm,
      figure(image("../figures/dbscan_test/1.png"), caption: [
        Three falsely merged surfaces.
      ]), <dbscanfig:a>,
      figure(image("../figures/dbscan_test/2.png"), caption: [
        Surface with little noise.
      ]), <dbscanfig:b>,
      figure(image("../figures/dbscan_test/3.png"), caption: [
        Surface with a lot of noise.
      ]), <dbscanfig:c>,
      caption: [
        One iteration of the DBSCAN results. Clustering here was only done on derivative data not on spatial information, since the algorithm would otherwise only detect the fact that, of course, it is spatially connected. The algorothm detected 17, 3 and 0 Cluster respectively, showing too high dependency on the parameter.
      ],
      label: <dbscanfig>,
    )

    ==== Custom Plateau Algorithm for segment analysis

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

    In @fig:scores:squareornot the difference between using the square of the surface size and not using it is shown.
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






    === Completeness and Correctness of the Segmentation

    ==== Bigger Picture

    @DataCompleteness describes three core factors of important data quality, completeness, accuracy and consistency.
    However, our focus will be on completeness and accuracy, since consistency is not that relevant in the current use case.
    Consistency amongs data sets would also be hard to describe here exactly.
    A way of describing it would be that Segment Anything Model (SAM) receives reliable data across multiple roofs given to it, without mayor drops in their segmentation quality.
    We already tried to identify, whether all types of roofs are inside the dataset, while using the classification by the faulty input data.
    However consistency in this specific case would also mean that the algorithms score can be trusted regardless of roof type.
    As this would create an actual need for many testing examples and extended identification or clasification of our calculated examples, for now it will not be further discussed.
    Therefore the assumption is once again made, that an algorithm which performs well on normal roofs and normal roof type variations will also perform well on other roof types, for example flat roofs, and that normal and flat roofs make out the majority of the dataset.
    Further evaluation on special roofs may be postponed.

    Completeness can be interpreted as two things.
    For one, the entire data set of roofs has to ensure that all relevant types of roofs are represented.
    On the other hand, in this specific example we are rather using it to evaluate each individual segmentation from the algorithm which is to be given to SAM.
    In that sense, completeness means that the calculated segmentation includes the entire actual surfaces.

    Lastly, accuracy is the most important factor in this use case.
    @DataCompleteness2 differentiates between accuracy and reliability.
    While they describe reliability as not in itself contradicting, which could be interpreted as a pixel not being able to be part of multiple surfaces.
    This in not possible in the current algorithm, which is important, however, i still support the description of needing reliable data outputted from the segmentation algorithm in regards to whether we can trust the data to be correct.
    To describe this both factors, i will further only use accuracy or correctness.
    The algorithm has to ensure informational correctness, meaning the expactation is given, that all data identified as roof by the algorithm has to actually be part of the roof.
    Classifying pixels outside the house as roof could cause a big problem, whilest misclassifying one segment's pixels as part of another segment may cause problems, but not as severe ones which are either more easily fixable or may not even be a problem at all.
    Regardless, since misidentifyed roof segments even inside the entire roof structure are problematic, no bias towards either will be introduced, simplyfing the problem to does pixels belonging to the surface map onto exactly one real-world surface.

    ==== Segmentation Evaluation

    Remember, the primary objective of the segmentation calculated here is to provide sufficiently accurate points within each segment to prompt SAM.
    In turn, this means an incomplete segment will still be reduced to a valid point inside the real structure, while an incorrect segment could lead to an invalid point outdide the real structure.
    As this could confuse the model, it is important to ensure that the algorithm is correct, even if it is incomplete.
    Since SAM requires only hints of sufficient quality about the potential locations of surfaces, there is no actual need for the segmentation to be perfect.

    However, creating ground truths for the roofs is too time consuming, not feasible for the current project and in generel the very thing we are trying to avoid.
    Therefore a different approach was chosen.
    The scoring system shown in @scoring is used to evaluate the quality of the segmentation.
    If we trust that scoring system to accurately evaluate the quality of the segmentation, it's input points will be sufficient for further analysis.
    Running the algorithm and evaluating the performance on representaive houses will give us performance metrics on the algorithm, which in turn will give us a good idea on how well the algorithm performs on the given data.
    It must be acknowledged that of course testing the algorithm this way on only a few hand-picked houses may not serve as statistial proof.
    Since however, it is a good tradeof between objective evaluation and only medium effort neccessary, we may assume that the algorithm will perform similarly on other houses.

    Since we are not evaluating data sets but specific comparisons between a geometry representing a calculated surface and one representing a ground truth, we can break down the problem to be analyzed via the statistical metrics of recall and precision.
    Also, since we do have connected geographical structures without complex information structures, the problem can be simplified to be solved wit ha simple confusion matrix.
    This is possible since the tuple of pixel coordinates can be classified as true positives (TP), false positives (FP), and false negatives (FN) in a simple manner.
    @ConfusionMatrix shows such way of calculation for Object Classification, which can be adapted to the current problem.

    - Recall measures the completeness of the segmentation, meaning whether all or how much of the actual roof is covered by the calculated segmentation:
      $ "Recall" = "TP" / ("TP" + "FN") $ <formula:recall>

    - Precision measures the correctness of the segmentation, which answers the question of how accurate positive classifications by the alorithm are:
      $ "Precision" = "TP" / ("TP" + "FP") $ <formula:precision>

    ==== Execution

    While this may sound simple to calculate, the exact calculation must be discussed in further detail.
    There is the possibility of evaluating the entire structure. meaning the combination of all surfaces in regards to the ground truth structure overall.
    This may show us for example whether all pixels of the roof are identified correctly and how many pixel are identified as roof which are not.
    In regards to the actual task however, this is not sufficient, as it tells nothing about identifying indiviual surfaces correctly.
    Therefore, the evaluation must be done on a per-surface basis.
    This means that the recall and precision are calculated for each surface individually and then averaged to get the overall performance of the algorithm.
    The problem thereby is, that not all surfaces will be identified percetly.
    Some may very well be split apart into two surfaces, because of abnormalies inside the surface being detected on an edge, or for that matter edges in the direction of axes being by nature of higher contrast value, meaning easier for the algorithm to misclassify.
    This in turn leads to the problem of how to evaluate the recall and precision of a surface which is split into two surfaces.

    The easiest and probably best solution is a simple one to one mapping.
    For each ground truth surface, we must find the best calculated surface, determined by highest Intersection over Union (IoU) value.
    This is the best way because of various reasons.
    For one, assuming the algorithm would be perfect, a one to one mapping would actually be the expected result.
    Since we already decided the minor need for completeness, even relatively low values in that aspect are sufficient, as long as the correctness values are high.
    Having a low completeness may only be a sign that the algorithm splits surfaces too much, which would be a helpful hint, if we were trying to perfect it.

    In general, this is a problem about under- and oversegmentation @underAndOversegmentation @underAndOversegmentation2.
    Oversegmentation in this case means that one of the roof surfaces is split into multiple parts.
    This is not a mayor problem, as long as the parts are not misclassified, however, later we will need to address this problem as it may lead to multiple prompts for the same surface or would create prompts which would become invalid negative prompts for SAM.
    For now this Fragmentation needs to be kept in mind, but will not be algorithmically addressed in the segmentation calculation.
    Later work may try to fix this problem by dynamically merging surfaces and re-calculing the score, looking for improvements.

    The worse case is undersegmentation, which means that multiple roof surfaces are merged into one.
    This creates a wrong assumption about the general roofs part umber as well as may lead to wrong prompts for SAM, which should be avoided in any case.

    Whilest having said that, for general analysis @fig:scores:completeness shows the calculated recall and precision for different numbers of calculated surfaces matched to one ground truth surface.
    It is visible that the recall, here named correctness, is overall quite high, meaning a good accuracy of classified pixel.
    Whilest a perfect score would probably be impossible anyway, the only outlier can be seen in the blue and light brown surfaces on the lower left, where transition between house and ground is not clear.
    An overall high accuracy even in @fig:scores:completeness:d, where up to 10 surfaces are matched to one ground truth surface, is a good sign for the algorithm's performance.
    This means that even if one of the surfaces which could be described as wrong are transformed into SAM input prompts, there should not be a mayor problem in regards to correctness.
    However the problem is that there is no simple way of filtering out such surfaces, as they are not wrong in the sense of being misclassified, but rather in the sense of being split too much.
    One way of fixing this may be actual improvement on the algorithm, however, for now this problem will be ignored.
    There will of course be an effort in fixing this problem when actually doing the prompting, for example by dynamically choosing input prompts by surfaces which are not yet represented by earlier prompts, more on this later.

    To at least say it, the completeness of the surfaces is kind of as expected.
    The biggest improvement can be seen when upping the limit from one match to two, meaning a tendency to at least split surfaces once.
    Most smaller surfaces which are added in the higher limit runs in actuality add little to the resulting structure.
    As they have little impact on the overall score, they are not a mayor concern.
    This is only a problem on some instances, where small connections lead to relevant splitting, but because this is caused by low pixel images and approximations done, fixing this seams fairly unplausable without mayor time investment.

    #subpar.grid(
      columns: 2,
      gutter: 1mm,
      figure(image("../figures/scoring_algorithm/completeness/1.png"), caption: [
        Evaluation when enforcing exact 1 to 1 Matches
      ]), <fig:scores:completeness:a>,
      figure(image("../figures/scoring_algorithm/completeness/2.png"), caption: [
        Matching 2 Calculated Surfaces to 1 Ground Truth
      ]), <fig:scores:completeness:b>,
      figure(image("../figures/scoring_algorithm/completeness/4.png"), caption: [
        Matching 4 Calculated Surfaces to 1 Ground Truth
      ]), <fig:scores:completeness:c>,
      figure(image("../figures/scoring_algorithm/completeness/10.png"), caption: [
        Matching up to 10 Calculated Surfaces to 1 Ground Truth
      ]), <fig:scores:completeness:d>,
      caption: [
        Graphical representation of the calculated recall and precision for different numbers of calculated surfaces matched to one ground truth surface.
      ],
      label: <fig:scores:completeness>,
    )

    A useful metric for combining the two score values is the F1 score.
    However as already said since we do not strive for equal valuing of recall (completeness) and precision (correctness), there is a need to introduce a bias.
    Therefore, we are going to use the formula shown in @formula:fß, which is the so called Fß score, which generalizes the F1 score by adding a weighting coefficient ß to the formula. @Fß

    $ F_ß = ( 1 + ß² ) * ("precision" * "recall") / ((ß² * "precision") + "recall") $ <formula:fß>

    As the bias needs to be towards favouring the precision, the $F_0.5$ score will be used, which is the $F_ß$ score with $ß = 0.5$.
    Calculating those values for the one to one exact matches gives us a score of $F_β≈0.887$, which highlights the bias pretty well, as the harmonic mean would only be around 0.75.

    While it may make sense to actually not include the completeness in this calculation at all, it serves the purpose of creating a better comparability towards the scoring system.
    As in generel we are trying to use this as a metric for whether we can trust he scoring system, and that algorithm uses positive and negative scores, it simply makes sense.
    However we could argue that a removal of the negative score could also have the same effect, as we now clarified the irrelevance of missing pixel points inside the surfaces.
    I would rather not do this, as it would simply worsen the results, which may not be a real problem, but if it is not neccessary i would like to avoid doing it.
    // experimantal -> find out if this makes sense
    Regardless, the decision was made to also use the $F_0.5$ score wen calculating the final scores out of positive and negative scores.
    This introduces a bias towards bigger surfaces and lessens the impact of missing surface area.

    The actual comparison of the score calculated from the segmentation algorithm and it's comparison score towards the ground truth will be done via the Pearson coefficient shown in @formula:pearson.
    This calculation should give us a good idea on how well the scoring system is able to evaluate the segmentation algorithm.
    At the very least, a sinking score from the algorithm should mean reduced precision or recall, meaning a worse score in regards to the ground truth.
    By that assumption we when run on multiple segmentations given we expect a positive correlation between the two scores.
    The Pearson Coefficient should then output a positive value close to 1, which would mean a high correlation between the two scores.

    $ r = (n * sum(x * y) - sum(x) * sum(y)) / sqrt((n * sum(x^2) - sum(x)^2) * (n * sum(y^2) - sum(y)^2)) $ <formula:pearson>

    === Experiments

    ==== Logarithm <log>

    Using the Logarithm on the original, but normalized, nDSM Image data will help to enhance the contrast of the image. This will not only make the image more visually appealing but also easier to interpret. 
    @fig:edp:log shows the difference when applying the Logarithm directly after calculating the derivative.
    It is observable that the image which contains logarithmic normalization has less extreme maxima and minima, which makes it easier to interpret the image, due to the smaller values being more prominent, leading to a more balanced image in intensity.
    In the Image not using logarithmic scaling, most colours become very pale whilest only the extreme values on for example the edges of the house become intensively coloured, leading to the fact, that the image becomes hard to interpret by human eyes when trying to evaluate or validate the calculated data.
    The results of both are of quite different quality, which is due to the parameter of 'clipped percentage’ and input parameter for the Canny Edge Detection algorithm. 
    It appears that they could be changed in such a way that both images are much more similar in quality, but this is not researched in depth until after @scoring, when better experimentation is possible due to the scoring system.
    For now, further experiments will continue to use the logarithmic normalization, as it is a simple and effective way to enhance the contrast of the image, which in turn results in a wider or better scope for parameter tuning.

    #figure(
      image("../figures/apply_log/Result.png", width: 100%),
      caption: [
        Comparison between using the Logarithm on the original nDSM Image data and the original nDSM Image data without prior adjustments.
      ],
    ) <fig:edp:log>

    ==== Edge Detection

    @ScharrOperator

    ==== Blurring

    @GaussianOperator
  ]

  pagebreak()
}