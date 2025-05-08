#import "templates/terms.typ": get_key

#let _used_abbreviations_ = state("used_abbreviations", ())
#let update_counter = state("update_counter", 0)

#let abr(input) = {
    context {
        let data = get_key(input)
        let (short, long) = (data.at(0), data.at(1))

        // Handle the state and find out if it was used before
        let all_used_abbreviations = _used_abbreviations_.get()
        let used = all_used_abbreviations.any(item => item == short)

        let link-text = if not used { 
            long + " (" + short + ")"
        } else { 
            short
        }

        link("#term-" + short)[#link-text]
    }

    _used_abbreviations_.update(lst => {
		lst.push(input)
		return lst
	})
    update_counter.update(c => c + 1)
}

#import "templates/thesis.typ": project
#import "metadata.typ": details
#import "modules/00_intro.typ": intro
#import "modules/00_data.typ": data
#import "modules/01_basics.typ": basics
#import "modules/01_using_sam.typ": sam
#import "modules/02_algorithm.typ": ndsm_analysis
#import "modules/03_truth_compare.typ": truth_compare
#import "modules/04_ablation.typ": ablation
#import "modules/05_SAM.typ": sam_inclusion
#import "modules/conclusion.typ": conclusion

#show: body => project(details, body)

// 0
#intro(abr)
#data()

// 1
#basics(abr)
#sam()

// 2
#ndsm_analysis()

// 3
#truth_compare(abr)

// 4
#ablation()

// 5
#sam_inclusion()

// 6
#conclusion()


#pagebreak()