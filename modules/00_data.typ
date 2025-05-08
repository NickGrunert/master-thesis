#import "@preview/subpar:0.2.0"

#let data() = {
  text(lang:"en")[
    = Input Data Analysis <section:input_data>
    The input data for this research needs to be collected, described and analysed.
    The aim is to identify existing data and make an initial assessment of whether and how it can be used for the research.

    == Data Collection
    @fig:input:image_and_ndsm shows the surface tile which will be used, split into RGB image and an image which illustrates the nDSM data.
    The RGB data is derived from aerial imigery, provided by the State Office for Geoinformation and Surveying of Lower Saxony (LGLN).

    #figure(
      image("../figures/input/image_and_ndsm.png"), 
      caption: [Image and nDSM Input Data],
    ) <fig:input:image_and_ndsm>

    Specifically, the tile chosen was 326045790, located in the city of Braunschweig, Germany.
    This was chosen for a number of reasons.
    Most importantly, the LGLN was able to provide me with data from a building recognition AI, combined with other data that had already been collected on roof structures.
    As the tile is on the outskirts of the city, it contains many "normal" houses, which range from low complexity to medium number of segments, and are therefore of average complexity, which is more suitable for analysis.
    Analysing a house with a very high number of segments is not helpful if no segments can be detected at all.
    It is therefore necessary to find relatively simple, but not too easily identifiable, roof structures to enable the most effective research.
    Similarly, roof structures that are too complex or special, such as spires, will not be useful initially, but will be of interest later, after the general effectiveness is proven.

    This data consists of four different geo-json files.
    @fig:input:comparison shows the visual representation of the geometries present in the four data sets for one example house.

    On the left is a simple building base area.
    These are the results of the building detection AI and contain some additional information in addition to the geometries.
    Especially noteworthy are the detected area of the geometry and the algorithm's confidence in the detection.

    #figure(
      image("../figures/input/data_comparison.png"), 
      caption: [Image and nDSM Input Data],
    ) <fig:input:comparison>

    The other three geometries shown are related to each other via id references.
    From left to right, they contain only the roof area, specific roof segments and then the building parts that make up these segments, becoming more specific at each step.
    The building area contains no additional information, thus providing no basis for evaluating its quality, as was the case with the initial geometry.
    The roof data, in principle, contains a substantial amount of information that could be useful if it were available, including the pitch and type of roof.
    In the event that such data were already available with sufficiently good quality, this research would not be necessary, as the objective of this research is to explore ways to create such data.
    It is unfortunate that the quality of the exact segmentations in this data is very poor, since the segments do not reflect the actual roof segments accurately.

    == Filtering
    Data from the established sources needs to be filtered to improve reliability and overall quality.
    A training set of poor quality is detrimental to later analysis by machine learning algorithms @dataQuality3.
    Models must first work with or be trained on a correct data set in order to learn the correct features and generalise.
    This will later allow them to detect errors in test data, but erroneous training data is expected to reduce model performance @dataQuality4.
    Filtering to produce high quality data will generally improve performance compared to using an unfiltered large dataset @smallData2.
    A small set of high quality data will outperform a large low quality data set @smallData1.
    Therefore, this section describes the filtering process using statistical analysis.

    Initially, this is simply a matter of removing duplicates and filtering out buildings that are either completely outside the area of the tile, or that even partially overlap its boundaries.
    The result is a list of buildings that are unique and completely within the tile's area, not cut off.
    
    Each building will be used as an individual image for the analysis.
    For each individual building, an axis-aligned bounding box is calculated, which subsequently serves as the image bounds.
    The area of the bounding box is calculated in addition to the area of the building itself.

    Buildings that are too large are filtered out, as they fall into the category of being unnecessarily complex.
    The bounding box can be utilised to calculate the ratio of the building area to bounding box area.
    This is a measure of how well the building fits into the bounding box.
    Houses that are very stretched or have an irregular shape will have a low ratio, while houses that are more conventional will have a higher ratio.
    Note that a square house can have a ratio as low as 50% due to geometric rotation towards the axis.

    While the building parts themselves are of poor quality in measuring the actual shape of the building, their number can be used as an indicator of the complexity of the building.
    For each building bounds, the number of overlapping building parts is calculated.
    Most buildings do not appear to have a large number of parts.
    However, some of them exceed the scale, with up to almost 250 parts.
    Closer analysis reveals that this is a general sign that the building contains many rounded segments, as these are broken down into many individual triangular segments within the geometries.

    #subpar.grid(
      columns: (3fr, 1fr),
      gutter: 2mm,
      figure(image("../figures/input/heatmaps.png")),
      figure(image("../figures/input/build_parts.png")),
      caption: [
        Heatmaps over the data's geometries
      ],
      label: <fig:input:heatmaps>,
    )

    @fig:input:heatmaps displays the geometries in question as a heatmap. The building area is shown in the first heatmap, the bounding box area is displayed in the second, the ratio between the two is shown in the third and the number of building parts is shown in the fourth row.
    The presence of an excessively large area is often indicative of unnecessary complexity.

    The presence of a large bounding box in and of itself does not pose a problem; a large building will naturally have a large bounding box.
    However, the ratio between these two metrics has been demonstrated to serve as an indicator of potentially problematic buildings, as structures with a low ratio are generally considered undesirable, as they do not serve as effective exemplars.

    Next, @fig:input:statistics lays down the statistics over the identified relevant data, showing the distribution as bar plots as well as line plots with median and mean values.
    Note that the plots do not show 7%, 11% and 12% of the values for overlapping building parts, area and bounding box area respectively for better visualisation.
    The differences between median and mean are particularly striking.
    It is normally expected that the data for each of the graphs will be approximately normally distributed.
    The observed discrepancies between median and mean can be attributed to errors in the data.

    #subpar.grid(
      columns: 2,
      gutter: 2mm,
      figure(image("../figures/input/before_filter/area.png")),
      figure(image("../figures/input/before_filter/confidence.png")),
      figure(image("../figures/input/before_filter/bbox.png")),
      figure(image("../figures/input/before_filter/roof_parts.png")),
      caption: [
        Input data statistics
      ],
      label: <fig:input:statistics>,
    )

    The presence of buildings with close to zero area, the distribution of confidence values down to 50%, and the absence of overlapping building parts can be attributed to erroneous identification of buildings. 
    Additionally, these errors are not statistically independent, but rather exhibit a correlation with the fact that buildings of virtually negligible size are often also not present in the building part data set and of low confidence.
    @fig:input:area_correlation shows the direct correlation between building area and algorithm confidence, as well as building area and bounding box area.

    #subpar.grid(
      columns: 2,
      gutter: 0mm,
      image("../figures/input/bbox_to_area.png"), 
      image("../figures/input/area_to_confidence.png"),
      caption: [
        Area Correlation
      ],
      label: <fig:input:area_correlation>,
    )

    The area exhibits an overall good correlation with the bounding box area.
    However, there are buildings that act as outliers by having very large bounding boxes.
    In the graphs, the values chosen as filter cut-offs are visualised as lines.
    For the correlation between area and bounding box area, by visual confirmation, 30% seems to be a good compromise between not filtering too many buildings and filtering out the worst offenders.
    It can be visually confirmed that most buildings are not below this threshold, indicating that the filtering is not too strict.

    The correlation between area and confidence was investigated, with thresholds of 50 m² and 90% being selected for this purpose.
    It is conceivable that 50 m² may be selected with less than optimal consideration.
    Utilising this threshold effectively eliminates the majority of irregularities and errors.
    The majority of structures in proximity to this threshold are of a rudimentary design, such as huts or garages with a single roof. These structures are deemed to lack the requisite complexity to serve as valuable input data.
    Nevertheless, filtering by this value removes the anomalous spike in the size of buildings close to zero that was shown in @fig:input:statistics.
    The 90% confidence level was chosen after visual confirmation of the data, which shows a clear increase in correctly defined data points above this threshold.

    The filtering of building parts is done by removing all buildings without overlapping building parts.
    While most of these will already be filtered out by confidence, it will still be done as there is no guarantee.
    The maximum number of building parts allowed per building is set to 100.
    This allows some very complex buildings to be filtered out, while still allowing some examples of shapes such as spire roofs.

    Although the specific data on roof types and roof segments may not reflect the truth very accurately, they can still serve as an indicator of roof type.
    Therefore, the subsequent filtering step will filter out all buildings where all segments are marked as flat roofs.
    This is done because the original distribution shown in @fig:input:types shows the prevalence of these roof types in the data.
    Flat roofs are generally considered to be simple, and a more diversified, unbiased distribution of the overall data is also desired to improve its overall quality as input data for machine learning @dataQuality2.
    
    ```
    Buildings before filtering:                     2444
    Buildings after filtering by confidence:        1715
    Buildings after filtering by size:              1629
    Buildings after filtering by area percentage:   1566
    Buildings after filtering by building parts:    1548
    Buildings after filtering by only flat roofs:   1258
    ```

    Note that in the first step, the largest number of buildings was filtered out by confidence, as this contains the most information about actually usable buildings, or conversely, unusable buildings.
    The visualisation of the buildings removed in each step confirms that the filtering works well.
    Buildings removed by confidence are mainly complete misclassifications or very erroneous data.
    Removal by no overlap is due to the same reasons or, more noticeably, to inconsistencies in the different datasets, presumably due to different timeframes of data collection.

    Buildings removed by maximum size are mainly large industrial buildings, whereas those removed by small size are huts or similar.
    The majority of the smaller buildings were previously filtered out on account of their correlation with low confidence levels.
    Filtering by area percentage had the intended effect of filtering out, for example, long stretched canopies on the platform, or the station itself due to its odd shape resulting in a very large bounding box.

    #subpar.grid(
      columns: 2,
      gutter: 0mm,
      image("../figures/input/types.png"),
      caption: [
        Roof types before and after filtering
      ],
      label: <fig:input:types>,
    )

    This filter, as well as filtering for flat roofs only, produces the distribution of roof types shown in @fig:input:types on the right.
    The general distribution does not change, but the bias towards a predominant portion of the data being flat roofs is slightly reduced.
    Note that the two disappearing roof types are the GambrelHipRoof, which is a misclassification, and the Barrelroof, which is a small arched roof.
    The latter is a minor loss of information, as it is part of a large building with a complex shape and many building parts, which is considered too complex for evaluation.
    
    Example images of buildings and the reason for their removal are shown in the appendix.

    == Entry data
    The algorithms and methods employed in this research are subject to plausibility checks.
    It became apparent that the current dataset was of such a size that it could not be analysed in its entirety; therefore, a smaller selection was required.
    Therefore, the dataset will be sorted according to the area size.
    The subsequent experiments will primarily utilise the initial 20 houses located at the 60th percentile.

    The input data is processed so that the following algorithms receive an RGB image of the house, the nDSM data within this area frame, and the building parts as an image mask.
    Note that this mask may not reflect the structure of the building well, but can be used as a rough estimate of the building boundaries and as a basis for later analysis.
    Its exact use will be explained later.

    @fig:input:result_example shows two examples of the processed dataset.
    Note that the masks shown are not the final product, as they will be pre-processed to exclude building parts that do not belong to the current building in question.
    The second entry shows such an invalid overlap in the lower left corner, which will be filtered out before further use.

    The nDSM image is displayed using a terrain colour map for visual clarity, as the raw nDSM data in a spectrum from white to black does not have enough contrast to show clear detail.

    #subpar.grid(
      columns: (2fr, 1fr),
      gutter: 0mm,
      box(figure(image("../figures/prompts/example_entry_1.png")), clip: true, width: 100%, inset: (right: -200%)),
      box(figure(image("../figures/prompts/example_entry_1.png")), clip: true, width: 100%, inset: (left: -500%)),
      box(figure(image("../figures/prompts/example_entry_2.png")), clip: true, width: 100%, inset: (right: -200%)),
      box(figure(image("../figures/prompts/example_entry_2.png")), clip: true, width: 100%, inset: (left: -500%)),
      caption: [
        Example entry data sets
      ],
      label: <fig:input:result_example>,
    )
  ]
}