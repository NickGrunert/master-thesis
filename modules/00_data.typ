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