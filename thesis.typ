#import "templates/thesis.typ": project
#import "metadata.typ": details
#import "modules/data.typ": data
#import "modules/prompting.typ": prompting
#import "modules/ndsm_analysis.typ": ndsm_analysis
#import "modules/03_truth_compare.typ": truth_compare
#import "modules/04_SAM.typ": sam_inclusion

#show: body => project(details, body)

#data()

#prompting()

#ndsm_analysis()

#truth_compare()

#sam_inclusion()
