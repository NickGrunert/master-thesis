#import "templates/thesis.typ": project
#import "metadata.typ": details
#import "modules/data.typ": data
#import "modules/prompting.typ": prompting
#import "modules/ndsm_analysis.typ": ndsm_analysis
#import "modules/01_using_sam.typ": sam
#import "modules/03_truth_compare.typ": truth_compare
#import "modules/04_SAM.typ": sam_inclusion

#show: body => project(details, body)

//#data()

//#prompting()



// 1
#sam()

// 2
#ndsm_analysis()

// 3
#truth_compare()

// 4
//#sam_inclusion()
