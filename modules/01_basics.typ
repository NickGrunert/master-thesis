#import "@preview/subpar:0.2.0"

#let basics(abr) = {
  text(lang:"en")[
    = Basics

    == Normalized Digital Surface Model (nDSM)
    The #abr("nDSM") is derived by subtracting the #abr("DEM") from the #abr("DSM"), both of which are generated using LiDAR point cloud data @ndsm5.
    The #abr("DEM") is a representation of the earth's bare surface, while the #abr("DSM") encompasses the earth's surface and all objects on it, such as buildings and vegetation.
    It is important to note the existence of the #abr("DTM"), which is occasionally used interchangeably with the #abr("DEM"), but can also incorporate additional features beyond those of the #abr("DEM") @ndsm4.
    The extraction of building structures is heavily reliant on the utilization of #abr("DSM") data, as it contains pivotal information regarding the height of buildings and other objects on the surface @extractUAV.

    The extraction of structures from #abr("nDSM") data constitutes a pivotal task in the fields of remote sensing and geospatial analysis. 
    This process is exemplified in the context of 3D building reconstruction @ndsm3.
    However, the #abr("nDSM") data is vulnerable to noise and artifacts.
    Given that the #abr("nDSM") is derived from the #abr("DSM") and #abr("DEM"), inaccuracies in both data sources, such as interpolation artifacts or missing data, can compromise the integrity of the #abr("nDSM").
    A multitude of potential error sources have been identified, including the #abr("DSM") and #abr("DEM") being recorded not at the same time, the utilization of disparate sensors, and inherent inaccuracies in these sensors.
    Additionally, the integrity of #abr("nDSM") data may be compromised by the presence of temporary objects which are in the LiDAR data @ndsm1 or residual noise stemming from algorithmic inaccuracies @ndsm2.

    In light of the aforementioned limitations on the quality of the #abr("nDSM") data, it is necessary to exercise caution in the subsequent evaluation of this research and to be aware of them or eventually handle them.

    == Segment Anything Model (SAM)
    // TODO
  ]
}