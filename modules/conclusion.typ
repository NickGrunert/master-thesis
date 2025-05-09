#import "@preview/subpar:0.2.0"

#let conclusion() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )

    = Conclusion and Future Work
    In the context of this research, computer vision techniques were explored to extract salient geometric features that could serve as the basis for generating geometric prompts for SAM. 
    Key techniques such as edge detection, segmentation, and morphological operations were evaluated for their suitability in identifying fine-grained features within building rooftops, which are essential for precise segmentation. 
    Methods such as the Sobel operator and the Canny edge detector were tested to highlight boundaries and sharp transitions in the nDSM data. 
    Additionally, morphological transformations like dilation and erosion were applied to refine and enhance the features extracted from the raw data.
    Ultimately, the most effective methods were those that captured both the structural details of the building roofs and the variation in height, allowing for more granular and accurate prompt generation.

    An automated pipeline was developed by combining several pre-processing techniques and algorithms to transform raw nDSM data into sets of effective geometric prompts for SAM. 
    The workflow began with data pre-processing steps like noise reduction and normalization of nDSM data, followed by feature extraction using the computer vision techniques identified in the previous objective. 
    Geometric features such as sharp corners, ridges, and roof edges were extracted and translated into point-based prompts, which are the key input for SAM. 
    The pipeline also incorporated automated evaluation metrics to assess the quality of the generated prompts. 
    Evaluation focused on both the precision of feature extraction and the consistency of the geometric representations, which are crucial for obtaining high-quality segmentations with SAM. 
    As part of the refinement process, feedback loops were integrated into the pipeline to iteratively improve the prompt generation based on the performance of SAM.

    The performance of SAM was evaluated by comparing its results when guided by geometric prompts generated through the proposed pipeline with those obtained using less informed or manual prompting strategies. 
    The evaluation was conducted by applying the geometric prompts to SAM and analyzing the resulting building roof segmentations. 
    Performance metrics included accuracy (e.g., Intersection over Union or IoU), completeness (e.g., coverage of the building roof areas), and geometric fidelity (e.g., alignment of the segmentation with the true roof edges). 
    The results were compared against other segmentation approaches, including SAM with random or no prompts, and manual prompting strategies. 
    The evaluation highlighted that SAM, when guided by the geometric prompts generated through this methodology, achieved higher segmentation accuracy and better preservation of geometric features in comparison to less informed or manual methods. 
    This demonstrated the effectiveness and potential of geometric prompts in fine-grained roof segmentation tasks.
  ]
}