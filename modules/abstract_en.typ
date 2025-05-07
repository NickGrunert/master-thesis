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
    The utilization of deep learning models in the analysis of geospatial data has witnessed significant advancements over the past decade. 
    These advancements have had a profound impact on various fields, including environmental monitoring, disaster management, urban planning, and cadastre. 
    By leveraging deep learning techniques, researchers and practitioners can extract, analyze, and interpret vast amounts of spatial data, leading to more accurate and timely insights.

    Deep learning techniques are currently employed for the purpose of building extraction in aerial images using semantic segmentation or instance segmentation techniques @abstract1.
    However, fine-grained analyses, such as building part instance segmentation, roof plane segmentation, or other semantic attributes of building roofs like material coverage, are hindered by the lack of training data. 
    Notwithstanding the critical importance of this information for the development of AI-based applications, such as 3D building reconstruction or solar potential analysis, the data scarcity remains a significant barrier.

    The Segment Anything Model (SAM) @sam has exhibited noteworthy zero-shot generalization capabilities across a range of image datasets. 
    This model has the capacity to segment objects without the necessity of specific training, rendering it a promising instrument for remote sensing applications. 
    Nevertheless, further investigation is necessary to ascertain the performance of the system in the remote sensing domain @abstract2, particularly in complex scenes and with varying image resolutions.

    The objective of this research is to address the aforementioned gap by adapting and evaluating the SAM for fine-grained building analysis tasks in aerial imagery or multimodal data combining aerial images with data from normalized Digital Surface Models (nDSM).
    nDSM data provides elevation information, which can be crucial, especially for distinguishing intraclass objects such as individual roof segments.
    Recent research has explored and demonstrated the potential of applying SAM to remote sensing applications @abstract3.
    However, its performance on fine-grained building analysis tasks, especially when using nDSM data, remains under-explored.
    The correct usage of SAM, the selection of appropriate parameters, and the evaluation of its performance on fine-grained building analysis tasks are critical aspects that need to be addressed.
    In order to ascertain the validity of using SAM in such tasks, an analysis will need to be conducted to evaluate which input data may serve best in achieving this objective.
  ]
  
  v(1fr)

  pagebreak()
}