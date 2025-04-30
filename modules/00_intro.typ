#let intro() = {
  text(lang:"en")[

    = Introduction




    == Related Work

    == Definitions

    == Input Data Analysis


    Wang et al @ruralBuildingRoofTypes roof types are listed into 5 categories: gabled, flat, hipped, complex and mono-pitched. about 91,6% of their training set's roofs where almost evenly split between gabled and flat roofs






    In the paper @buildingContours the problem of separating buildings is described

    The paper @extractUAV uses DSM data for additional picture information to separate buildings from flora

    @dataQuality1 describes that duplicates can decrease the ai quality by creating a wrong bias
    
    @dataQuality2 highlights the importance of a balanced dataset to avoid a bias in the ai model and the relevance of completeness

    @dataQuality3 describes the importance of a high quality dataset for the ai model to work properly, as bad input data will always lead to bad output data

    @dataQuality4 describes how error in the training data can greatly decrease the ai model's performance

    @smallData1 stresses the importance of a high quality dataset, as a small high quality dataset can outperform a large low quality dataset

    @smallData2 says how good quality / filtering of data can increase the performance in contrast to using an unfiltered large dataset

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