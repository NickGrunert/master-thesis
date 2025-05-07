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

    == Input Data

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



    /*
    Wang et al @ruralBuildingRoofTypes roof types are listed into 5 categories: gabled, flat, hipped, complex and mono-pitched. about 91,6% of their training set's roofs where almost evenly split between gabled and flat roofs

    In the paper @buildingContours the problem of separating buildings is described

    @dataQuality1 describes that duplicates can decrease the ai quality by creating a wrong bias
    
    @dataQuality2 highlights the importance of a balanced dataset to avoid a bias in the ai model and the relevance of completeness

    @dataQuality3 describes the importance of a high quality dataset for the ai model to work properly, as bad input data will always lead to bad output data

    @dataQuality4 describes how error in the training data can greatly decrease the ai model's performance

    @smallData1 stresses the importance of a high quality dataset, as a small high quality dataset can outperform a large low quality dataset

    @smallData2 says how good quality / filtering of data can increase the performance in contrast to using an unfiltered large dataset

    */

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