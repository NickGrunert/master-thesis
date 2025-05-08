#import "@preview/subpar:0.2.0"

#let data() = {
  text(lang:"en")[
    = Input Data Analysis

    == Normalized Digital Surface Model (nDSM)
    The nDSM is derived by subtracting the Digital Elevation Model (DEM) from the Digital Surface Model (DSM), both of which are generated using LiDAR point cloud data @ndsm5.
    The Digital Elevation Model (DEM) is a representation of the earth's bare surface, while the Digital Surface Model (DSM) encompasses the earth's surface and all objects on it, such as buildings and vegetation.
    It is important to note the existence of the Digital Terrain Model (DTM), which is occasionally used interchangeably with the Digital Elevation Model (DEM), but can also incorporate additional features beyond those of the DEM @ndsm4.
    The extraction of building structures is heavily reliant on the utilization of DSM data, as it contains pivotal information regarding the height of buildings and other objects on the surface @extractUAV.

    The extraction of structures from nDSM data constitutes a pivotal task in the fields of remote sensing and geospatial analysis. 
    This process is exemplified in the context of 3D building reconstruction @ndsm3.
    However, the nDSM data is vulnerable to noise and artifacts.
    Given that the nDSM is derived from the DSM and DEM, inaccuracies in both data sources, such as interpolation artifacts or missing data, can compromise the integrity of the nDSM.
    A multitude of potential error sources have been identified, including the DSM and DEM being recorded not at the same time, the utilization of disparate sensors, and inherent inaccuracies in these sensors.
    Additionally, the integrity of nDSM data may be compromised by the presence of temporary objects which are in the LiDAR data @ndsm1 or residual noise stemming from algorithmic inaccuracies @ndsm2.

    In light of the aforementioned limitations on the quality of the nDSM data, it is necessary to exercise caution in the subsequent evaluation of this research and to be aware of them or eventually handle them.

    == Data Collection

    The input data for this research needs to be collected, described and analysed.
    The aim is to identify existing data and make an initial assessment of whether and how it can be used for the research.

    @fig:input:image_and_ndsm shows the surface tile which will be used, split into RGB image and an image which illustrates the nDSM data.
    The RGB data is derived from DOP20 (Digital Orthophotos at 20 cm resolution), provided by the State Office for Geoinformation and Surveying of Lower Saxony (LGLN).

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
    Similarly, roof structures that are too complex or special, such as spires, will not be useful initially, but will only be of interest later, when the general effectiveness is proven.

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
    However, the quality of this data is so poor that its use is highly questionable.
    The building area contains no additional information, so we have nothing to base its quality on, as we did with the first geometry.
    The roof data theoretically contains a lot of information that could be useful if it were available, such as the pitch and type of roof.
    In the first case, if such data were already available in good quality, this research would not be necessary, as we are researching ways to create such data.

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

    For each building, an axis aligned bounding box is calculated, which is used as the image bounds later on.
    The area of the bounding box is calculated in addition to the area of the building itself.
    Buildings that are too large are filtered out, as they fall into the category of being unnecessarily complex.

    The bounding box can be used to calculate the ratio of the building area to the bounding box area.
    This is a measure of how well the building fits into the bounding box.
    Houses that are very stretched or have an irregular shape will have a low ratio, while houses that are more conventional will have a higher ratio.
    Note that a square house can have a ratio as low as 50% due to geometric rotation towards the axis.

    While the building parts themselves are of poor quality in measuring the actual shape of the building, their number can be used as an indicator of the complexity of the building.
    Rather than using the segmentation data that is directly mapped to the building parts, the overlap between the building detection data and the roof data segments is calculated.
    This is done to align the building used to create the bounding box with the roof data, as there is no guarantee that the building detection data and the segmentation data are aligned.
    Row houses are particularly affected, as the segmentation splits individual houses within the row, while the geometry used for the bounding box uses the whole row.

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

    @fig:input:heatmaps shows the geometries in question coloured as a heatmap for the building area, the bounding box area, the ratio between the two and the number of building parts.
    An area that is too large generally means unnecessary complexity.
    A large bounding box itself is not a problem, as a large building will have a large bounding box.
    However, the third row, showing the ratio between them, shows problematic buildings, as buildings with a low ratio are generally undesirable, as they do not serve as good examples.

    Most buildings do not appear to have a large number of parts.
    However, some of them exceed the scale, with up to almost 250 parts.
    Closer analysis reveals that this is a general sign that the building contains many rounded segments, as these are broken down into many individual triangular segments within the geometries.

    Next, @fig:input:statistics lays down the statistics over the identified relevant data, showing the distribution as bar plots as well as line plots with median and mean values.
    Note that the plots do not show 7%, 11% and 12% of the values for overlapping building parts, area and bounding box area respectively for better visualisation.
    The differences between median and mean are particularly striking.
    Normally one would expect the data to be approximately normally distributed.
    The discrepancy here is due to errors in the data, which affect all of these graphs as they are not independent of each other.

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

    The high peaks at very small building areas, the distribution of confidence values down to 50% and buildings without overlapping building parts are due to incorrectly identified buildings.
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

    The correlation between area and bounding box area is clearly good.
    However, there are clearly buildings that act as outliers by having very large bounding boxes.
    In the graphs, the values chosen as filter cut-offs are visualised as lines.
    For the correlation between area and bounding box area, 30% seemed to be a good compromise between not filtering too many buildings and filtering out the worst offenders.
    It can be visually confirmed that most buildings are not below this threshold, indicating that the filtering is not too strict.

    For the correlation of area and confidence, thresholds of 50 m² and 90% were chosen.
    However, 50 may be a little low.
    At this value most irregularities and errors are filtered out, but the buildings close to this threshold are mostly of very simple shape, for example huts or garages with a single roof.
    Nevertheless, filtering by this value removes the anomalous spike in the size of buildings close to zero that was shown in @fig:input:statistics.
    The 90% confidence level was chosen after visual confirmation of the data, which shows a clear increase in correctly defined data points above this threshold.

    The filtering of building parts is done by removing all buildings without overlapping building parts.
    While most of these will already be filtered out by confidence, it will still be done as there is no guarantee.
    Also, as mentioned above, the maximum number of building parts allowed is set to 100.
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
    Most of the small buildings were already filtered out before.
    Filtering by area percentage had the intended effect of filtering out, for example, long stretched conopies on the platform, or the station itself due to its odd shape resulting in a very large bounding box.

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
    The latter is a small loss of information as it is also part of a large building with a complex shape and many parts that are not very useful anyway.

    // TODO say that removed images are in appendix?

    == Results
    The filtered houses are sorted by size.
    The algorithms and methods used in this research are subject to plausibility checks.
    As the current dataset was far too large to analyse in its entirety, a smaller selection was required.
    This selection consists mainly of the first 20 houses at the 60th percentile of area from the dataset, with some other houses used occasionally, especially in initial experiments to create baseline assumptions.

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