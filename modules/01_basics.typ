#import "@preview/subpar:0.2.0"

#let basics(abr) = {
  text(lang:"en")[
    = Fundamental Concepts

    == Normalized Digital Surface Model (nDSM)
    The #abr("DEM") from #abr("DSM") are two sets of data which are generated using #abr("LiDAR") point cloud data @ndsm5.
    The #abr("DEM") is a representation of the earth's bare surface, while the #abr("DSM") encompasses the earth's surface and all objects on it, such as buildings and vegetation.
    It is important to note the existence of the #abr("DTM"), which is occasionally used interchangeably with the #abr("DEM"), but can also incorporate additional features beyond those of the #abr("DEM") @ndsm4.
    The extraction of building structures is heavily reliant on the utilization of #abr("DSM") data, as it contains pivotal information regarding the height of buildings and other objects on the surface @extractUAV.

    The calculation of the #abr("nDSM") is achieved by the subtraction of the #abr("DEM") from the #abr("DSM"), thus providing a representation of the height of objects above the ground.
    The extraction of structures from #abr("nDSM") data constitutes a pivotal task in the fields of remote sensing and geospatial analysis. 
    This process is exemplified in the context of 3D building reconstruction @ndsm3.
    However, the #abr("nDSM") data is vulnerable to noise and artifacts.
    Given that the #abr("nDSM") is derived from the #abr("DSM") and #abr("DEM"), inaccuracies in both data sources, such as interpolation artifacts or missing data, can compromise the integrity of the #abr("nDSM").
    A multitude of potential error sources have been identified, including the #abr("DSM") and #abr("DEM") being recorded not at the same time, the utilization of disparate sensors, and inherent inaccuracies in these sensors.
    Additionally, the integrity of #abr("nDSM") data may be compromised by the presence of temporary objects which are in the #abr("LiDAR") data @ndsm1 or residual noise stemming from algorithmic inaccuracies @ndsm2.

    It will be necessary to exercise caution in subsequent evaluations and to be aware of the aforementioned limitations on the quality of the #abr("nDSM") data.

    == Segment Anything Model (SAM)
    Having zero-shot capabilities means that the model can perform tasks without prior training on specific examples of those tasks.
    In this way, #abr("SAM") is able to adapt to new tasks and data, making it a versatile and powerful tool for any image segmentation operation @sam3.
    #abr("SAM") is able to create detailed segmentation masks to precisely outline objects in the image, unlike original object detection models that only draw rectangles around them.
    Such segmentation masks follow the exact shape of objects, providing a more accurate understanding of the shape, size and position of the object in question @sam1.
    
    The model has three core components:
    First, #abr("SAM") uses a #abr("ViT") architecture to encode the input image.
    This model is the backbone of the entire algorithm and is available in several different variants, each representing a trade-off between complexity and performance.
    The second component is a prompt encoder, which is able to analyse different types of input prompts given to #abr("SAM") to guide the segmentation process.
    Finally, the model returns segmentation masks that must be decoded by a lightweight mask decoder.
    In terms of performance, @sam2 is considered to be competitive with, or even superior to, fully supervised models.
    
    Specifically, this research will use the #abr("SAM")2 model, which is an evolution of the original model in that it can segment video, but also has improved performance on image data.
    However, as this work does not have data such as time series, video analysis will not be relevant here.
    The memory attention mechanic of the improved model will simply not be relevant to this research, as images can be viewed as a single-frame video @sam4.

    The core mechanic of #abr("SAM") is the ability to prompt the model with a variety of different types of prompts, most prominently as points or bounding boxes.
    These define the area of interest for the model, and #abr("SAM") will then segment the image based on these prompts.
    With input points, the model also provides the ability to define what can be called positive and negative points.
    A positive point is a point inside the object of interest, while a negative point annotates background outside the object of interest.
  ]
}