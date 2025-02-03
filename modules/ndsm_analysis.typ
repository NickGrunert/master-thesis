#import "@preview/subpar:0.2.0"

#let ndsm_analysis() = {
  text(lang:"en")[
    == NDSM Analysis
    Since we clarified the need for better ground truths to enable trustworthy prompting, this section will focus on algorithmic analysis of the NDSM data.
    The goal is to create a pipeline which is able to segment the roof of a house into individual surfaces which in contrast to the input data as accurately as possible represent the roof's structure.
    The following theories will provide a basis for the development of the pipeline:
    - The NDSM data contains the height information of the roof, which can be used to generate derivatives across the roof.
      Therefore, this data can be used to create viable segmentations of the roof.
    - There are multiple aspects about the optimal segmentation which may be hard to algorithmically approach.
      For example, the algorithm may have problems with surfaces which are not perfectly even in their derivative values.
      This is due to the fact that the algorithm may split the surface into multiple surfaces, as it detects a sudden change in the derivative values.
      This is a problem, as most roof surfaces are not perfectly even in their derivative values, for reasons as simple as the existence of roof tiles, that we would like to not regard solar panels as a separate surface or even round roof tiles.
    - Not only can the algorithm create segmentations, but it can also evaluate the quality of the generated surfaces.
      By analyzing the derivative values the surfaces can be evaluated using the coherence of the values.
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
    The pipeline starts with the calculation of the derivative of the NDSM data using the Sobel operator @SobelOperator.
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

    A crucial step in the pipeline is blurring the data.
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
    There were attempts to use erosion and dilation to achieve this, but they were not successful, as they lead to the algorithm not being able to detect thin roof parts.
    Simply put, no matter how small for example the erosion kernel was, it would always lead to too many pixels being lost, meaning in turn small or thin parts of the roof would be filtered out, due to the small image size.
    As this was not satisfying, the current approach of pixel categorization was developed, as it also simplifies re-adding the removed pixel.
    
    However as this may lead to some real surfaces being split into multiple surfaces, a re-linking step is neccessary.
    For this, the algorithm calculates the mean derivative of each surface and connects surfaces which are close enough in their mean derivative.
    This should in generel give a good result, as the mean derivative of a surface should be quite similar across the whole surface whilest the derivative of two distinct surfaces should be different enough to not be connected.
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

    === Scoring System <scoring>
    It became clear, that a function is neccessary to evaluate the quality of the generated surfaces.
    This function should be able to evaluate the quality of the surfaces based on the following criteria:
    - The coherence of the surface's values, meaning that optimaly the surface should have a similar value over the whole surface.
      While realistically this value will not achieve a perfect score, it should be as high as possible.
      This is due to the fact that most roof surfaces are not perfectly even is derivative values.
      In experiments it becomes clears that almost no surface has a perfect derivative across all values or if it does, it is also possible that an actually bigger surface go split too much by the algorithm.
    - The size of the surface. 
      To address the algorithm cutting down surfaces too much, I propose to add a reward for bigger surfaces.
      This should be done in a way that the reward is not too big, as it could lead to the algorithm just merging all surfaces into one big surface.
      A bigger surface which is not coherent should be penalized accordingly.

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

    For this purpose a custom algorithm was developed which evaluates the quality of a surface.
    It does this by analyzing each surfaces derivative values, in each direction meaning x, y and their combination.
    For each direction the algorithm tries to generate plateaus, which are areas with a similar derivative value, or at least not sudden changes in the derivative value.
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

    === Experiments

    ==== Logarithm <log>

    Using the Logarithm on the original, but normalized, NDSM Image data will help to enhance the contrast of the image. This will not only make the image more visually appealing but also easier to interpret. 
    @fig:edp:log shows the difference when applying the Logarithm directly after calculating the derivative.
    It is observable that the image which contains logarithmic normalization has less extreme maxima and minima, which makes it easier to interpret the image, due to the smaller values being more prominent, leading to a more balanced image in intensity.
    In the Image not using logarithmic scaling, most colours become very pale whilest only the extreme values on for example the edges of the house become intensively coloured, leading to the fact, that the image becomes hard to interpret by human eyes when trying to evaluate or validate the calculated data.
    The results of both are of quite different quality, which is due to the parameter of 'clipped percentage’ and input parameter for the Canny Edge Detection algorithm. 
    It appears that they could be changed in such a way that both images are much more similar in quality, but this is not researched in depth until after @scoring, when better experimentation is possible due to the scoring system.
    For now, further experiments will continue to use the logarithmic normalization, as it is a simple and effective way to enhance the contrast of the image, which in turn results in a wider or better scope for parameter tuning.

    #figure(
      image("../figures/apply_log/Result.png", width: 100%),
      caption: [
        Comparison between using the Logarithm on the original NDSM Image data and the original NDSM Image data without prior adjustments.
      ],
    ) <fig:edp:log>

    ==== Edge Detection

    @ScharrOperator

    ==== Blurring

    @GaussianOperator
  ]

  pagebreak()
}