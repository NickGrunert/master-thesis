#import "templates/thesis.typ": project
#import "metadata.typ": details
#import "modules/00_intro.typ": intro
#import "modules/02_algorithm.typ": ndsm_analysis
#import "modules/01_using_sam.typ": sam
#import "modules/03_truth_compare.typ": truth_compare
#import "modules/04_ablation.typ": ablation
#import "modules/05_SAM.typ": sam_inclusion
#import "modules/conclusion.typ": conclusion


#show: body => project(details, body)


// 0
#intro()

// 1
#sam()

// 2
#ndsm_analysis()

// 3
#truth_compare()

// 4
#ablation()

// 5
#sam_inclusion()

// 6
#conclusion()
