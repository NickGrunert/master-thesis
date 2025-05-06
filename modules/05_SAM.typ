#import "@preview/subpar:0.2.0"

#let sam_inclusion() = {
  text(lang:"en")[
    = Including SAM into the algorithm
    In this section, the Segment Anything Model (SAM) will be implemented on the provided dataset.
    Specifically, the process will be analogous to previous iterations, wherein it will be executed on the portion of the dataset that contains ground truth data.
    This approach enables the utilization of preexisting algorithms for scoring and analysis, facilitating a comparative assessment of the performance of SAM.

    Due to the absence of empirical evidence regarding the efficacy of SAM in analyzing specific data and the necessary inputs for optimal performance, the subsequent section will generate diverse input images based on each house's data. 
    This will facilitate the analysis of the impacts of varying data configurations.

    Furthermore, an experiment will be conducted in which a variety of methods are utilized for the purpose of invoking the model.
    This encompasses various configurations and quantities of input suggestion points for SAM, as well as the subsequent utilization of negative suggestions, which are incorporated for each surface from diverse surfaces in an attempt to enhance the model's performance.

    == Filtering of generated Segmentations

    #subpar.grid(
      columns: 1,
      gutter: 0mm,
      box(figure(image("../data/6/5/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in, right: -0.7in, left: -1.0in)),
      box(figure(image("../data/6/18/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.6in, top: -0.6in, right: -0.7in, left: -1.0in)),
      box(figure(image("../data/6/8/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.2in, right: -0.7in, left: -1.0in)),
      caption: [
        Impact of Filtering or Dilution on the Generated Segmentations.
      ],
      label: <fig:sam:dilution>,
    )

    == Experiment Results

    This section presents the findings from the experiments that employed the aforementioned methods, utilizing input images and segmentation to generate the input prompts.
    The results of this study will be thoroughly analyzed and compared to ascertain the viability of the proposed solutions.
    This also includes improvements to the algorithm, which become apparent through this analysis.
    The result of this process will be a final algorithm capable of generating the optimal segmentation for the specified dataset with minimal computational effort. 
    Consequently, a definitive assessment of the segmentation's quality will be rendered.

    #subpar.grid(
      columns: 4,
      gutter: 1mm,
      figure(image("../data/6/19/sam/best/mask.png"), caption: [
        Mask
      ]), <fig:sam:results2:a>,
      figure(image("../data/6/19/sam/best/generated.png"), caption: [
        Generated
      ]), <fig:sam:results2:b>,
      figure(image("../data/6/19/sam/best/filtered.png"), caption: [
        Filtered
      ]), <fig:sam:results2:c>,
      figure(image("../data/6/19/sam/best/dilated.png"), caption: [
        Dilated
      ]), <fig:sam:results2:d>,
      figure(image("../data/6/1/sam/best/mask.png")),
      figure(image("../data/6/1/sam/best/generated.png")),
      figure(image("../data/6/1/sam/best/filtered.png")),
      figure(image("../data/6/1/sam/best/dilated.png")),
      caption: [
        Best SAM results for each Input Segmentation.
      ],
      label: <fig:sam:results2>,
    )

    As illustrated by @fig:sam:results2, a brief comparison is presented among representative outcomes attained through the implementation of disparate input segmentations.
    The objective of this process is to identify the optimal segmentation among the possible inputs and strategy types used to generate input prompts.

    The results evidently demonstrate the mask's deficiency in generating optimal segmentations. However, they do illustrate that for more rudimentary segmentations, it can achieve a moderate level of success.
    The program's inability to identify smaller surfaces encapsulated within larger surfaces is particularly problematic, as these surfaces do not generate their own prompts and are instead usurped by the larger surface in the output.
    It has been determined that some larger segments are absent due to the imprecise input prompts, since they lie within smaller inner surfaces generating better masks. 
    Consequently, the algorithm is unable to locate the larger segment due to the absence of a prompt to calculate the outer surface from.

    A direct comparison of the results obtained from the use of generated surfaces and filtered surfaces reveals minimal differences.
    This finding indicates that the presence of small, fragmented surfaces in the generated surfaces is neither problematic for the algorithm not beneficial.
    Consequently, this signifies that the filtering process is preferable, as it is capable of removing a significant proportion of those fragments. 
    This, in turn, reduces the amount of data that requires processing, thereby significantly decreasing execution time.

    @tab:sam:input displays the current results by score for each input segmentation.
    However, it must be noted that the reliability of the data presented in this table is questionable.
    The discrepancy between the use of generated surfaces and filtered surfaces is negligible, if it exists at all.
    As demonstrated in @fig:sam:results2, the dilation process was capable of smoothing the result segmentation through the filtration of numerous minute surfaces, a factor that did in fact exert an influence on the outcome.
    However, the dilation process has generally been too aggressive in filtering many surfaces. As indicated by the dataset, numerous small roof segments were only detected by thin generated surfaces. 
    These surfaces survived the filtering but not the dilation. This resulted in a loss of information and, consequently, the statistics shown.

    #subpar.grid(
      table(
        columns: (1fr,1fr,1fr,1fr,1fr),
        rows: 2,
        inset: 10pt,
        align: center,
        table.header(
          [], [Mask], [Generated], [Filtered], [Dilated]
        ),
        [Number], [0], [3], [13], [4],
      ),
      caption: [
        Table of the best Results for each Input Segmentation.
      ],
      label: <tab:sam:input>
    )








    #subpar.grid(
      table(
        columns: (1fr,1fr,1fr,1fr,1fr),
        rows: 3,
        inset: 10pt,
        align: center,
        table.header(
          [],       [(n=1)], [(n=2)], [(n=3)], [(n=4)]
        ),
        [Center],   [2], [5], [2], [4],
        [Combined], [2], [1], [2], [2],
      ),
      caption: [
        Table of the best results for each Strategy.
      ],
      label: <tab:sam:strategy>
    )

  ]
}