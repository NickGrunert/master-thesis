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
    The data from the established sources need to be filtered in order to improve reliability and overall quality.
    A training set of subpar quality will be detrimental for later analysis by machine learning algorithms @dataQuality3.
    Models must first learn on a correct set of data, to learn the correct features and to be able to generalize.
    With that, they will later be able to identify errors in test data, however, having errorneous training data will lead to a decrease in model performance @dataQuality4.
    Filtering to create high quality data will generally increase the performance in contrast to using an unfiltered large dataset @smallData2.
    A small high quality dataset is expected to outperform a large, low quality dataset @smallData1.
    Therefore, this section will describe the filtering process by statistical analysis.

    In the beginning, this simply entails removal of duplicates and filtering of buildings which are either completely outside the tile's area or even partly overlapping the bounds set.
    This way, a list of buildings emerges, which are unique and completely within the tile's area, not cut off.

    An axis aligned bounding box is calculated for each building, which is to serve as the image crop for later use.
    Additionaly to the buildings area itself, the area of the bounding box is calculated.
    Buildings of too high size will be filtered out, as they fall into the category of being unnecessarily complex.

    Using the bounding box, the ratio of the building area to the bounding box area can be calculated.
    This is a measure of how well the building fits into the bounding box.
    Houses which are very stretched or of irregular shape will have a low ratio, while houses which are more conventional will have a higher ratio.
    Note that a squared house can have a ration as low as 50 percent due to geometrical rotation not aligning with the axis.

    While the building parts themselves are of subpar quality in measuring the actual shape of the building, their number may serve as an indicator of the complexity of the building.
    Instead of using the segmentation data, which directly maps to the building parts, overlap between the building detection data with the roof data segments is calculated.
    This is done to align the building used for bounding box creation with the roof data, since there is no guarantee that the building detection data and the segmentation data are aligned.
    Especially row houses will be affected by this, since the segmentation splits singular houses inside the row, while the geometry used for the bounding box uses the entire row.

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

    @fig:input:heatmaps shows the geometries in question colored as a heatmap for the building area, the bounding box area, the ration between the two and the number of building parts.
    An excessively large area generally menas unneccessary complexity.
    A big bounding box itself is not problematic, since a big building conversly has a big bounding box.
    However, the third row showing the ratio between them showcases problematic buildings, as buildings with a low ratio are generally not desirable, because they do not serve as good examples.

    Most buildings appear to not have a high amount of building parts.
    However, some of them exceed the scale, having up to almost 250 building parts.
    Closer analysis reveals that this is a general sign of the building containing a lot of rounded segments, since those are split into many individual triangular segments inside the geometries.

    Next, @fig:input:statistics lays down the statistics over the identified relevant data, showing the distribution as bar plots as well as line plots with median and mean values.
    Note that the graphs are cutting off 7%, 11% and 12% for overlapping building parts, area and bounding box area respectively in order for better visualisation.
    Particularly notable are the differences between median and mean.
    Normally, the assumption could be made that the data should roughly be normally distributed.
    The discrepancy here stems from errors inside the data, which affects all of these graphs, since they are not independent of each other.

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

    The high peaks at very low building area, distribution of confidence ranging as low as 50% and buildings without overlapping building parts are attributable to incorrectly identified buildings.
    @fig:input:area_correlation shows the direct correlation between building area and algorithm's confidence, as well as building area and bounding box area.
    
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

    The correlation between area and bounding box area is visibly well.
    Nonetheless, there are clearly buildings which serve as outliers in the fact of having very large bounding boxes .
    In the graphs, the values which are chosen as filtering cut-offs are visualized as lines.
    For the correlation between area and bounding box area, 30% seemed a good trade-off between not filtering to many buildings and filtering out the worst offenders.
    It can be visually confirmed that most of the buildings are not belowe this threshold, indicating that the filtering is not too strict.

    For correlation of area and confidence, the thresholds were decided to be 50 m² and 90%.
    However, 50 may chosen a bit low.
    At this value, most irregularities and errors are filtered out, the buildings close to this threshold however are mostly of very simple shape, for example shacks or garages with one singular roof.
    Nonetheless, filtering by this value removes the errorneous spike of buildings size close to zero, which was shown in @fig:input:statistics.
    The confidence threshold of 90% was chosen after visual confirmation of the data showing a clear increase in correctly defined data points.

    Filtering of building parts will be done by removing all buildings with no overlapping building parts.
    While most of these will be filtered out already by confidence, it will be done regardless, since there is no guarantee for this.
    Also, as mentioned, the maximum number of allowed building is set to 100.
    This allows for filtering of some extensively complex buildings, while still mentaining some examples for shapes like spire roofs.

    Whilest the specific data of the about the type of roofs and roof segments may not very accurately reflect the truth, it still may serve as an indicator of the type of roof.
    Therefore, the consequent filtering step will filter out all buildings, in which all segments are marked as flat roofs.
    This is done because the original distribution shown in @fig:input:types demonstrates the previlance of those types of roofs in the data.
    Flat roofs are generally condsidered simple, and also having a more diversified, non biased distribution of overall data is desired to improve its general quality as input data for machine learning @dataQuality2.
    
    ```
    Buildings before filtering:                     2444
    Buildings after filtering by confidence:        1715
    Buildings after filtering by size:              1629
    Buildings after filtering by area percentage:   1566
    Buildings after filtering by building parts:    1548
    Buildings after filtering by only flat roofs:   1258
    ```

    Notice that the highest number of buildings was filtered out by confidence in the first step, since this holds the most information about actually viable buildings, or conversly about unusable buildings.

    // TODO

    #subpar.grid(
      columns: 2,
      gutter: 0mm,
      image("../figures/input/types.png"),
      caption: [
        Roof types before and after filtering
      ],
      label: <fig:input:types>,
    )


    == Results

    // TODO

    #stack(
      image("../figures/prompts/example_entry_1.png", width: 100%),
      h(4cm),
    )
    #stack(
      image("../figures/prompts/example_entry_2.png", width: 100%),
      h(4cm),
    )
  ]
}