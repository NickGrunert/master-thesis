#let intro(abr) = {
  text(lang:"en")[
    = Introduction

    // TODO ?

    == Related Work
    #heading(depth: 5, numbering: none, bookmarked: false)[Evolution of Roof Segmentation Techniques]
    A long-standing challenge in photogrammetry and computer vision is the automated extraction of building roofs from remotely sensed data, such as aerial and satellite imagery.
    Nevertheless, this is of critical importance for applications such as 3D city modeling, urban planning, and solar potential assessment.
    Early approaches relied on traditional computer vision techniques applied to imagery, often augmented by elevation data such as a #abr("DSM") or point clouds derived from #abr("LiDAR") @intro1.
    These methods frequently involved analyzing geometric properties, using edge detection, region growing, or morphological operations to identify building structures or roof segments in general.
    While these data-driven methods are indeed effective to a certain degree, they frequently encounter challenges related to incompleteness and noise that are inherent to the input data.
    This encompasses both low contrast in imaging and reduced point density in #abr("LiDAR"), particularly with respect to intricate roof structures comprised of multiple minute segments that are challenging to discern @intro2.

    The advent of #abr("DL") has led to substantial progress in advanced semantic segmentation capabilities, particularly through the implementation of #abr("CNN") and #abr("FCN"), for example by U-Net @intro3 and SegNet @intro4.
    In circumstances where a sufficient amount of labeled data is available, these models have been shown to frequently exhibit superior performance in comparison to traditional methodologies by learning hierarchical features.
    U-Net is a frequently utilized architecture for the purpose of detecting the base area of buildings and roof segmentation @intro5. 

    Nevertheless, #abr("DL") approaches encounter substantial challenges in the domain of remote sensing.
    A primary concern is the scarcity of large-scale, diverse, and accurately labeled datasets, especially for complex tasks such as the accurate segmentation of roof planes.
    The manual creation of annotations and ground truth data requires a lot of manual labor, which severely restricts the size and variability of training sets.
    Additionally, remote sensing data demonstrates a high degree of variability, attributable to various factors including, but not limited to, the utilized sensors, the resolution of the sensors, atmospheric conditions, and the inherent diversity of buildings across disparate geographical locations @intro6. 
    This makes model generalization difficult @intro7. 
    Roof segmentation presents a series of unique challenges, including the handling of complex geometries, the obstruction by overlapping trees and shadows, and the accurate delineation of specific internal rooflines such as ridges, hips, and valleys @intro8.

    #heading(depth: 5, numbering: none, bookmarked: false)[Enhanced Segmentation through Multi-modal Data Fusion]
    The utilization of multiple data sources has become a prevalent approach to address the constraints imposed by a single data source. 
    Integration of information obtained from standard images with geometric information derived from elevation data has emerged as a common practice @intro7. 
    Elevation data, particularly the #abr("nDSM"), which represents height above ground, provides strong cues for distinguishing buildings from ground features and understanding their structure @intro9.
    Common fusion strategies in #abr("DL") involve the incorporation of the nDSM or features derived from #abr("LiDAR") as additional input channels alongside RGB or multispectral bands @intro10.
    This enables networks to acquire knowledge collectively from spectral and geometric information, frequently resulting in enhanced segmentation accuracy, particularly for architectural structures such as buildings.
    Other approaches utilize elevation data in post-processing steps. 
    One such approach employs a #abr("CRF") @intro_bonus1 @intro_bonus2 to refine segmentation boundaries generated from image-based models.
    While fusion generally improves results, it requires accurately co-registered multimodal datasets, which can also be challenging to acquire and label.

    #heading(depth: 5, numbering: none, bookmarked: false)[Foundational Models: The Segment Anything Model (SAM)]
    Recent advancements in #abr("AI") have resulted in the development of large "foundational models" that are trained on massive datasets. 
    These models are designed to generalize, and they have been shown to exhibit remarkable generalization capabilities @intro11. 
    A prominent example is the #abr("SAM") from Meta AI @intro10. 
    #abr("SAM") has been trained on a dataset comprising over one billion masks and has been developed as a promptable segmentation system.
    Given a prompt such as input points or bounding boxes, #abr("SAM") can segment any object in an image, even those unseen during training, demonstrating impressive zero-shot performance. 
    It's architecture involves three components: a lightweight prompt encoder, a heavy #abr("ViT") for image encoding, and a fast mask decoder @intro_bonus3.

    #heading(depth: 5, numbering: none, bookmarked: false)[#abr("SAM") in Remote Sensing: Adaptations and Challenges]
    The potential zero-shot capabilities of #abr("SAM") when working in data-scarce domains, such as remote sensing, has generated considerable interest.
    Nonetheless, its implementation has frequently yielded suboptimal outcomes.
    The challenges associated with this process include the following:
    -	sensitivity to the lower spatial resolutions common in satellite imagery
    -	differences in object characteristics compared to natural images
    -	its inherent dependency on prompts
    The manual generation of prompts is an impractical approach for large-scale analysis.
    Additionally, #abr("SAM") performs class-agnostic segmentation, which involves the identification of object masks without the assignment of semantic labels.
    Consequently, research has focused on adapting #abr("SAM") for remote sensing tasks with several strategies that aim to automate or improve the prompting process:
    
    - Adapters and Fine-tuning: 
      RSAM-Seg @intro12 is an example of a model that incorporates lightweight adapter modules within #abr("SAM"), meticulously calibrated using remote sensing data.
      RSAM-Seg employs image-derived features, including high-frequency components derived from the fast Fourier transform, to autonomously generate prompts. 
      This process eliminates the need for manual intervention and enhances performance in tasks such as building detection.
      PSP-SAM @intro13 employs progressive self-prompting, generating internal visual prompts and external mask prompts based on features learned from optical imagery for salient object detection.
    
    - Integration with Other Models: 
      The utilization of output masks generated by #abr("SAM") has been demonstrated in the context of multi-scale segmentation algorithms. 
      These masks have been employed as constraints, or integrated with semantic pseudo-labels derived from alternative models within the framework of unsupervised domain adaptation, a strategy exemplified by SAM-EDA @intro14. 
      Conventional CNNs have also been proposed as a means of prompt generation for #abr("SAM").

    // TODO ich versteh hier nix von
    Novel Prompting Strategies: Researchers have explored the use of text prompts in conjunction with one-shot learning or employing segmentation outputs from other models as input prompts.
    The aforementioned adaptations underscore the necessity of effective modification in the context of leveraging #abr("SAM") in remote sensing, particularly with regard to addressing its inherent limitations, such as the requirement for automated, domain-relevant prompting.
    It is important to note that a considerable number of automated prompting strategies are contingent upon features derived from the image itself @intro15.

    #heading(depth: 5, numbering: none, bookmarked: false)[Integrating Elevation Data with Foundational Models]
    While the value of elevation data is well-established for traditional CV and standard #abr("DL") segmentation models, its integration specifically with foundational models like #abr("SAM") is still an emerging area.
    The following are examples of such approaches:

    Elevation Data for Refinement: The STEGO @intro18 framework utilizes features from a self-supervised DINO model for initial segmentation and subsequently refines the results using a #abr("CRF") that incorporates #abr("nDSM") information in a post-processing step.

    #abr("SAM") for 3D Point Clouds: SAMNet++ @intro16 adapts #abr("SAM") for 3D LiDAR point clouds (SAM LiDAR) by segmenting a 2D rasterized, colorized representation based on color as well as texture information, followed by refinement via PointNet++ @intro17.
    In this case, initial segmentation relies on color in the 2D projection rather than on 3D geometry directly.

    == Tools <section:tools>
    A variety of tools were used during this work.
    In the context of research, in addition to manual inquiries through search engines, Perplexity AI @perplexity was employed as a contemporary search engine that utilizes artificial intelligence to locate relevant sources.
    Moreover, Connected Papers @connectedpaper was utilized to identify related publications for particular sources.
    
    The implementation phase was executed through the utilization of Google Colab @colab, a cloud-based collaborative coding platform, to circumvent the necessity for local setup and to leverage cloud-based #abr("GPU").
    The integrated Google Gemini AI @gemini was utilized for minor code completion; however, this was only the case for non-complex tasks of negligible importance.
    Additionally, it was used during debugging processes to identify errors. 
    However, this approach yielded at most modest success.

    The effectiveness of ideas and their subsequent implementation were partly validated through consultations with DeepSeek @deepseek and ChatGPT @chatgpt.
    Nevertheless, the prevailing focus in these cases is on the discussion of the validity of ideas and the construction of rudimentary frameworks for algorithms.
    It is noteworthy that the code created in these cases is rarely incorporated into the final product, since most of it had to be rewritten completely.

    While all texts in this work were originally written by the author, DeepL @deepl was used for text improvement.
    Specifically, it is notable for its ability to rewrite text in an academic style, thereby enhancing its quality, and conducting grammar checks.
    However, these texts were not simply adopted directly; rather, they underwent a thorough review process that often involved their rewriting, as their language was often considered overly sophisticated.

    == Motivation

    // deep learning hat viele fortschritte und viele domains, räumlicher bereich fehlt noch research und trainingsdaten
    // deep learning kann komplexe daten erkkennen -> viel potential 
    // 
    // viele anwendungen würden von LOD3 profitieren aber das sind halt sehr schiwerige model, segmentierung für sehr hohe level
    // 
    // foundation model wurden schon auf viel daten trainiert darum muss keine  basis erst trainiert werden, sam ist praktisch weil hints/prompts
    // erstellung von prompts automatisieren
    // 
    // TODO talk about LOD2

    == Research Questions

    How effective is the zero-shot learning capability of #abr("SAM") in accurately segmenting building roof details, particularly individual roof segments, without prior training?
    What improvements can be achieved by implementing a one-shot learning approach using input prompts for the segmentation of building roof details, or which method is best?

    How well does #abr("SAM") generalise to different roof materials and structures?
    Can we develop strategies to improve the adaptability of #abr("SAM") to different building types and reduce the need for fine tuning?

    How can nDSM data be effectively incorporated into the #abr("SAM") segmentation process to improve the accuracy of building analysis tasks?
    Can we develop a fusion mechanism that combines features from RGB and nDSM data to improve the segmentation of building components?

    Design and implement an automated training data generation workflow.
    Conduct real-time segmentation experiments on aerial imagery and document the practical challenges and solutions.
  ]
}