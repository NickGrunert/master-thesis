#let prompting() = {
  text(lang:"en")[
    Hree could be your ads

    


    #stack(
      // Top image spanning both columns
      image("../figures/prompts/example_entry_1.png", width: 100%),
      h(4cm),

      // Two-column layout for rows of stacked images
      // grid(
      //   columns: 4,
      //   gutter: 1cm,
      //   stack(
      //     text("Example Run 1"),
      //     image("../figures/prompts/ex2_1.png"),
      //     h(0.5cm),
      //     image("../figures/prompts/ex2_2.png"),
      //     h(0.5cm),
      //     image("../figures/prompts/ex2_3.png"),
      //     h(0.5cm),
      //     image("../figures/prompts/ex2_4.png"),
      //     h(0.5cm)
      //   ),
      // ),
    )

    Text in between

    #stack(
      // Top image spanning both columns
      image("../figures/prompts/example_entry_2.png", width: 100%),
      h(4cm),
    )
  ]

  pagebreak()
}