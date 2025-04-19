#import "templates/thesis.typ": project
#import "metadata.typ": details
#import "modules/data.typ": data
#import "modules/prompting.typ": prompting
#import "modules/ndsm_analysis.typ": ndsm_analysis
#import "modules/03_truth_compare.typ": truth_compare
#import "@preview/acrostiche:0.5.1": *

#show: body => project(details, body)

#init-acronyms((
  "MAE": ("Mean Absolute Error"),
  "MSE": ("Mean Squared Error"),
  "RMSE": ("Root Mean Squared Error"),
  "R2": ("R2 Score")
))

#print-index(row-gutter: 4pt, sorted: "down", title: "List of Abbreviations", level: 1)

= Example

#data()

#prompting()

#ndsm_analysis()

#truth_compare()
