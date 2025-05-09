#let abstract_en() = {
  v(1fr)
  
  align(
    center, 
    text(
      1em, weight: "semibold", 
      smallcaps("Abstract")
    )
  )
  
  text(lang:"en")[
    // @abstract2 @abstract3
    Deep learning has become a cornerstone technology for the analysis of vast quantities of image data prevalent in modern applications. This is largely due to the capacity of these models to autonomously learn intricate and hierarchical features directly from raw data.
    It is clear that a multitude of applications within the domain of remote sensing are set to benefit considerably from these sophisticated analytical capabilities.
    Nevertheless, a prevailing and critical hindrance obstructing the general adoption and performance of deep learning in this domain is the significant scarcity of adequately labelled training data.
    The advent of visual foundational models, such as Meta's Segment Anything Model (SAM) @sam, which was trained on an exceptionally large and diverse dataset, signifies a promising opportunity to alleviate the stringent requirements for extensive, specialised training datasets.
    
    The objective of this thesis is to address the challenge of adapting foundational models for specific, fine-grained remote sensing tasks.
    The primary objective of this research endeavour is the development and evaluation of a novel methodology that utilises the rich geometric information inherent in Digital Surface Models (DSMs) of building roofs.
    The information is utilised to automatically generate precise geometric prompts. These prompts are specifically designed for the detailed analysis of building roof structures in aerial imagery using SAM.
    In order to achieve this objective, a range of computer vision techniques are being investigated with a view to ascertaining their efficacy in generating prompts, which are frequently in the form of points denoting roof segments of a fine granular nature.
    The research systematically tests different automated prompt generation techniques, assesses their intrinsic quality, and subsequently conducts comprehensive experiments to demonstrate the performance of these geometrically-informed prompting strategies when applied to SAM for roof analysis using DSM-derived data.
    This work contributes a new pathway for enhancing detailed urban feature extraction by synergistically combining foundational models with auxiliary geospatial data, thereby mitigating data scarcity challenges in remote sensing.
  ]
  
  v(1fr)

  pagebreak()
}