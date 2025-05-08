#import "@preview/subpar:0.2.0"

#let sam_inclusion() = {
  text(lang:"en")[
    = Including SAM into the algorithm
    In this section, the Segment Anything Model (SAM) will be implemented on the provided dataset.
    Specifically, the process will be analogous to previous iterations, wherein it will be executed on the portion of the dataset that contains ground truth data.
    This approach facilitates the utilisation of preexisting algorithms for scoring and analysis, thereby enabling a comparative assessment on the performance of SAM.
    
    Due to the absence of empirical evidence regarding the efficacy of SAM in analyzing specific data and the necessary inputs for optimal performance, the subsequent section will generate diverse input images based on each house's data. 
    This will facilitate the analysis of the impacts of varying data configurations.

    Furthermore, an experiment will be conducted in which a variety of methods are utilized for the purpose of invoking the model.
    This encompasses various configurations and quantities of input suggestion points for SAM, as well as the subsequent utilization of negative suggestions, which are incorporated for each surface from diverse surfaces in an attempt to enhance the model's performance.

    == Filtering of generated Segmentations

    In this section, an analysis of the generated segmentations will be conducted. The objective of this analysis is to ascertain whether the segmentations can serve as adequate inputs for SAM in the subsequent sections.
    The objective is to establish input surfaces from which the discussed strategies can be applied to generate input prompts.
    
    Firstly, the analysis will continue to utilize the input mask for the time being.
    This comparison is intended to determine the potential for enhancement, as preliminary experimentation indicated that the mask's functionality is suboptimal.
    Consequently, the efficacy of the mask can be further assessed in this context, thereby serving as a pivotal point for comparative analysis of available alternatives.

    Secondly, the generated surfaces could be used as input without undergoing any refinement.
    However, due to the absence of refinement, these surfaces exhibit a high number of surfaces, resulting from the presence of numerous small fragments that infest areas with abnormalities, such as those observed around chimneys or other height variations, including ridges.

    Consequently, two distinct methods of filtering are proposed, both of which operate by filtering the surfaces by pixels adjacent to edges.
    The first method, referred to as "filtering," involves the removal of all directly adjacent pixels. 
    The second method, referred to as "dilation," involves the application of a 3x3 kernel for erosion, followed by the re-adding of the removed pixels via dilation @MorphologicalOperator. 
    This process effectively removes all surfaces that do not survive the initial erosion step.
    Nevertheless, the erosion and dilation process exhibits a more aggressive approach, also filtering over edge connections.

    #subpar.grid(
      columns: 1,
      gutter: 0mm,
      box(figure(image("../data/6/5/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.4in, top: -0.2in, right: -0.7in, left: -1.0in)),
      box(figure(image("../data/6/18/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.6in, top: -0.75in, right: -0.7in, left: -1.0in)),
      box(figure(image("../data/6/8/sam/surface_dilution.png")), clip: true, width: 100%, inset: (bottom: -0.2in, top: -0.4in, right: -0.7in, left: -1.0in)),
      caption: [
        Impact of filtering or dilution on the generated segmentations
      ],
      label: <fig:sam:dilution>,
    )

    The individual potential images for prompt generation are depicted in @fig:sam:dilution.
    The results obtained all demonstrate the potential for utilization.
    The reduction in the number of surfaces is clearly visible, with the filtering process being evidently more conservative.
    However, it is visible that certain small, but right, surfaces are filtered out subsequent to dilation.
    The results obtained led to the formulation of the theory that suggests the dilation process may not yield optimal solutions. 
    This is due to the hypothesis that the presence of additional fragments may have a less significant impact than the absence of specific surfaces, which may be critical.
    The subsequent section will present a detailed analysis of the outcomes, including the practical applications of SAM in this context.

    == Results

    This section presents the findings from the experiments that employed the aforementioned methods, utilizing input images and segmentation to generate the input prompts.
    The results of this study will be thoroughly analyzed and compared to ascertain the viability of the proposed solutions.
    Eliminating experimental inputs that demonstrate inefficient is of the utmost importance for enhancing the calculation time necessary to generate results for analysis.
    This also includes improvements to the algorithm, which become apparent through this analysis.
    The result of this process will be a final algorithm capable of generating the optimal segmentation for the specified dataset with minimal computational effort. 
    Consequently, a definitive assessment of the segmentation's quality will be rendered.

    #subpar.grid(
      columns: 4,
      gutter: 2mm,
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
        Best SAM results for each input segmentation
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
        columns: (1fr,1fr,1fr,1fr),
        rows: 2,
        inset: 10pt,
        align: center,
        table.header(
          [Mask], [Generated], [Filtered], [Dilated]
        ),
        [0], [3], [13], [4],
      ),
      caption: [
        Table of the best results for each input segmentation
      ],
      label: <tab:sam:input>
    )

    It is regrettable that the results displayed in @tab:sam:strategy lack the level of conciseness that was exhibited by the preceding results.
    A definitive tendency regarding the optimal number of input points remains elusive. 
    The disparities are more pronounced between each individual number than between the generated surfaces and the filtered surfaces.
    Moreover, the addition of negative points is nearly indispensable in certain instances, while in others, they prove to be of no discernible benefit.

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
        Table of the best results for each strategy
      ],
      label: <tab:sam:strategy>
    )

    It has been demonstrated that utilizing solely the positive center points appears to be the optimal strategy, with the employment of two or four points demonstrating a higher degree of proficiency.
    A number of additional observations can be made.
    The utilization of negative points was suboptimal, as the process of determining the most suitable surfaces from which to derive negative points was not executed in a dynamic manner.
    For instance, in place of merely selecting the largest other surfaces, it would be more advantageous to discern merged surfaces from the simple Center Strategy results and re-run the algorithm with those surfaces incorporated as negatives.
    This conclusion was derived from meticulous observation of the result segmentations, which exhibited such discrepancies even when employing the negative points in their present calculation method.
    
    Furthermore, an absence of direct correlation is observed between the results obtained from any Center Strategy and the Combined Strategy, given the utilization of an equivalent number of input points.
    A reasonable expectation would have been that the results would demonstrate some degree of similarity.
    However, this expectation was not met, which renders a direct comparison between the effectiveness of the two strategies unfeasible.

    @fig:sam:problem illustrates a magnitude of problem that came up when running SAM.
    First, the truth score was calculated the same way it was done in @section:truth_compare, which has not proven unsuccessful, but could be improved upon.
    The algorithm still favors correctness of the surfaces, but since we are no longer evaluating it's effectiveness in producing input prompts, but the actual surfaces themselves, the set bias no longer makes sense.
    The other way arround, favouring completeness would make sense now, since it better encapsulates the wanted correlation between ground truth and the generated surfaces.

    Secondly, the derivative data is still riddled with problemns stemming from noise and miscalculations from the height information.
    The small windows on the most top have a substantially wrong influence on the derivative.
    In this case, the RGB data outperforms, the execution on the derivative image, since such noise is not present, or in the case of the color swapped image less previlant enough to result in a smooth, correct surface.
    On the other hand, the example also shows pretty well that it cuts the big surface to the right in half, since there is a clear visual line between the segments.
    It could be argued that this is not of high importance, since the two individual surfaces can still be used to later generate the accurate structure of the house pretty well, or could be algorithmically merged.

    #subpar.grid(
      columns: 1,
      gutter: 0mm,
      figure(image("../figures/sam/problem.png")),
      caption: [
        Excerpt from SAM results
      ],
      label: <fig:sam:problem>,
    )

    Also, the RGB data serves in actually recognizing some edges between segments of equal derivative.
    This can be visually confirmed on the bottom right of the example house.
    Since the derivatives are equal, almost all experiments solely run on data derived from the nDSM are unable to recognize the edge.
    However, inclusion of the RGB data can solve this problem, as the colour swapped image and RGB image itself recognize this edge.

    Additionaly, it has become more apparent that the truth comparison should have a higher bias against segmentations which do not find generated segments for any ground truth segment.
    It has been proven that the mapping of score to ground score works.
    This is approved by the complete results of entire SAM algorithm executions, where the best results by score matches the best results by ground truth score.
    However, here, the visual confirmation is given that the effects of missing matches would preferebly be stronger, to better invalidate some results.
  ]
}