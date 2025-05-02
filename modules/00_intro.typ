#let intro() = {
  text(lang:"en")[
    = Introduction




    == Related Work
    #heading(depth: 5, numbering: none, bookmarked: false)[Evolution of Roof Segmentation Techniques]
    A long-standing challenge in photogrammetry and computer vision is the automated extraction of building roofs from remotely sensed data, such as aerial and satellite imagery.
    Nevertheless, this is of critical importance for applications such as 3D city modeling, urban planning, and solar potential assessment.
    Early approaches relied on traditional computer vision techniques applied to imagery, often augmented by elevation data such as a Digital Surface Model (DSM) or point clouds derived from Light Detection and Ranging (LiDAR) @intro1.
    These methods frequently involved analyzing geometric properties, using edge detection, region growing, or morphological operations to identify building structures or roof segments in general.
    While these data-driven methods are indeed effective to a certain degree, they frequently encounter challenges related to incompleteness and noise that are inherent to the input data.
    This encompasses both low contrast in imaging and reduced point density in LiDAR, particularly with respect to intricate roof structures comprised of multiple minute segments that are challenging to discern @intro2.

    The advent of deep learning (DL) has led to substantial progress in advanced semantic segmentation capabilities, particularly through the implementation of convolutional neural networks (CNNs) and fully convolutional networks (FCNs), for example by U-Net @intro3 and SegNet @intro4.
    In circumstances where a sufficient amount of labeled data is available, these models have been shown to frequently exhibit superior performance in comparison to traditional methodologies by learning hierarchical features.
    U-Net is a frequently utilized architecture for the purpose of detecting the base area of buildings and roof segmentation @intro5. 

    Nevertheless, deep learning (DL) approaches encounter substantial challenges in the domain of remote sensing.
    A primary concern is the persistent scarcity of large-scale, diverse, and accurately labeled datasets, especially for complex tasks such as the accurate segmentation of roof planes.
    The manual creation of annotations and ground truth data is a laborious and costly process, which severely restricts the size and variability of training sets.
    Additionally, remote sensing data demonstrates a high degree of variability, attributable to various factors including, but not limited to, the utilized sensors, the resolution of the sensors, atmospheric conditions, and the inherent diversity of buildings across disparate geographical locations @intro6. 
    This makes model generalization difficult @intro7. 
    Roof segmentation presents a series of unique challenges, including the handling of complex geometries, the obstruction by overlapping trees and shadows, and the accurate delineation of specific internal rooflines such as ridges, hips, and valleys @intro8.

    #heading(depth: 5, numbering: none, bookmarked: false)[Multi-modal Data Fusion for Enhanced Segmentation]
To mitigate the limitations of using single data sources, fusing spectral information from imagery with geometric information from elevation data (LiDAR, DSM, nDSM) has become increasingly common @intro7. Elevation data, particularly the normalized DSM (nDSM) which represents height above ground @intro9, provides strong cues for distinguishing buildings from ground features and understanding their 3D structure. Common fusion strategies in DL involve using the nDSM or LiDAR-derived features as additional input channels alongside RGB or multispectral bands @intro10. This allows networks to learn jointly from spectral and geometric information, often leading to improved segmentation accuracy, especially for buildings. Other approaches use elevation data in post-processing steps, for example, using Conditional Random Fields (CRFs) incorporating nDSM values to refine segmentation boundaries generated from image-based models. While fusion improves results, it often requires accurately co-registered multi-modal datasets, which can also be challenging to acquire and label.

    #heading(depth: 5, numbering: none, bookmarked: false)[Foundational Models: The Segment Anything Model (SAM)]
Recent advancements in AI have led to the development of large "foundational models" trained on massive datasets, exhibiting remarkable generalization capabilities [11]. The Segment Anything Model (SAM) from Meta AI is a prominent example in computer vision [10]. Trained on over a billion masks, SAM is designed as a promptable segmentation system. Given a prompt (e.g., points, bounding boxes, masks), SAM can segment virtually any object in an image, even those unseen during training, demonstrating impressive zero-shot performance. Its architecture typically involves a heavy image encoder (ViT), a lightweight prompt encoder, and a fast mask decoder.

    #heading(depth: 5, numbering: none, bookmarked: false)[SAM in Remote Sensing: Adaptations and Challenges]
The potential of SAM's zero-shot capabilities for data-scarce domains like remote sensing has spurred significant interest. However, direct application often yields suboptimal results. Challenges include SAM's sensitivity to the lower spatial resolutions common in satellite imagery, differences in object characteristics compared to natural images 36, and its inherent dependency on prompts.36 Generating manual prompts is impractical for large-scale analysis.36 Furthermore, SAM performs class-agnostic segmentation, identifying object masks without assigning semantic labels.384
Consequently, research has focused on adapting SAM for remote sensing tasks. Several strategies aim to automate or improve prompting:
Adapters and Fine-tuning: Models like RSAM-Seg [12] introduce lightweight adapter modules within SAM, fine-tuned on remote sensing data. RSAM-Seg uses image-derived features like high-frequency components (HFCs) from FFT to automatically generate prompts, eliminating manual intervention and improving performance on tasks like building detection. PSP-SAM [13] employs progressive self-prompting, generating internal visual prompts and external mask prompts based on features learned from optical imagery for salient object detection.
Integration with Other Models: SAM's outputs (masks) have been used as constraints for subsequent multi-scale segmentation algorithms 41 or fused with semantic pseudo-labels from other models within unsupervised domain adaptation frameworks like SAM-EDA [14]. Some propose using conventional CNNs as prompt generators for SAM.
Novel Prompting Strategies: Researchers have explored text prompts combined with one-shot learning  or using segmentation outputs from other models as input prompts.These adaptations highlight that leveraging SAM effectively in remote sensing often requires modifications to handle its limitations, particularly the need for automated, domain-relevant prompting. Notably, many automated prompting strategies rely on features derived from the image itself [15].

    #heading(depth: 5, numbering: none, bookmarked: false)[Integrating Elevation Data with Foundational Models]
While the value of elevation data (nDSM/LiDAR) is well-established for traditional CV and standard DL segmentation models, its integration specifically with foundational models like SAM is an emerging area. Some approaches exist:
Elevation Data for Refinement: The STEGO [18]framework uses features from a self-supervised model (DINO) for initial segmentation and then refines the results using a CRF that incorporates nDSM information in a post-processing step.

SAM for 3D Point Clouds: SAMNet++ [16] adapts SAM for 3D LiDAR point clouds (SAM LiDAR) by segmenting a 2D rasterized, colorized representation based on color/texture, followed by refinement with PointNet++ [17]. Here, SAM's initial segmentation relies on color in the 2D projection, not directly on 3D geometry.









    == Tools
    

    == Definitions


    /*
    Wang et al @ruralBuildingRoofTypes roof types are listed into 5 categories: gabled, flat, hipped, complex and mono-pitched. about 91,6% of their training set's roofs where almost evenly split between gabled and flat roofs






    In the paper @buildingContours the problem of separating buildings is described

    The paper @extractUAV uses DSM data for additional picture information to separate buildings from flora

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