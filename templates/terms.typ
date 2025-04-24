// ===== DEFINITIONS =====
#let abbreviations = (
  "MAE": (
    long: "Mean Absolute Error",
    desc: "Average of absolute differences between predicted and actual values",
    type: "abbr",
    used: false
  ),
  "MSE": (
    long: "Mean Squared Error",
    desc: "Average of squared differences between predicted and actual values",
    type: "abbr"
  ),
  "RMSE": (
    long: "Root Mean Squared Error",
    desc: "Square root of the average of squared differences between predicted and actual values",
    type: "abbr"
  ),
  "SAM": (
    long: "Segment Anything Model",
    desc: "A model for image segmentation that can identify and delineate objects in images",
    type: "abbr"
  ),
)

#let _used_abbreviations_ = state("used_abbreviations", ())
#let abr(input) = context{
  // Find matching term (case-sensitive)
  let matched-key = {
    for key in abbreviations.keys() {
      if key == input {
        key
      }
    }
    none
  }

  // Get the abbreviation data from the global list
  let term-data = abbreviations.at(matched-key)
  let short = matched-key
  let long = term-data.long

  // Handle the state and find out if it was used before
  let all_used_abbreviations = _used_abbreviations_.get()
  let used = all_used_abbreviations.any(item => item == short)

  if not used {
    all_used_abbreviations.push(short)
    _used_abbreviations_.update(all_used_abbreviations)
  }

  let link-text = if not used { 
    long + " (" + short + ")"
  } else { 
    short
  }

  link("#term-" + short)[#link-text]
}

#let abbreviation-list() = {
  set heading(level: 1)
  heading[List of Abbreviations]
  v(1em)
  
  // Sort terms alphabetically
  let sorted-terms = abbreviations.pairs().sorted(key: k => k.at(0))
  
  for item in sorted-terms {
    let term-key = item.at(0)
    let data = abbreviations.at(term-key)
    let is-abbr = data.type == "abbr"
    
    let needed-dots = 15 - term-key.len()
    let dots = if needed-dots > 0 { "．" * needed-dots } else { "" }
    let text = text(font: "Source Code Pro", weight: "bold")[#term-key] + " " + dots + "   "
    
    // Term header
    {set heading(level: 3)}
    [
      #text 
      #label("term-" + term-key) 
      #data.long
    ]
    v(0.1em)
  }
}
