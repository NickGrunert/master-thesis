#import "@preview/subpar:0.2.0"

#let sam_inclusion() = {
  text(lang:"en")[
    #show raw.where(block: true): block.with(
      fill: luma(240),
      inset: 10pt,
      radius: 4pt,
    )



    = Including SAM into the algorithm
    In this section, the Segment Anything Model (SAM) will be implemented on the provided dataset.
    Specifically, the process will be analogous to previous iterations, wherein it will be executed on the portion of the dataset that contains ground truth data.
    This approach enables the utilization of preexisting algorithms for scoring and analysis, facilitating a comparative assessment of the performance of SAM.

    Due to the absence of empirical evidence regarding the efficacy of SAM in analyzing specific data and the necessary inputs for optimal performance, the subsequent section will generate diverse input images based on each house's data. 
    This will facilitate the analysis of the impacts of varying data configurations.

    Furthermore, an experiment will be conducted in which a variety of methods are utilized for the purpose of invoking the model.
    This encompasses various configurations and quantities of input suggestion points for SAM, as well as the subsequent utilization of negative suggestions, which are incorporated for each surface from diverse surfaces in an attempt to enhance the model's performance.
  ]

  pagebreak()
}