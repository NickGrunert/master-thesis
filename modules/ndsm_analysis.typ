#import "@preview/subpar:0.2.0"

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

    === Scoring System
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
  ]

  pagebreak()
}