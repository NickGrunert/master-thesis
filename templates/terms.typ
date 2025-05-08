// ===== DEFINITIONS =====
#let abbreviations = (
  "MAE": (
    long: "Mean Absolute Error",
  ),
  "MSE": (
    long: "Mean Squared Error",
  ),
  "RMSE": (
    long: "Root Mean Squared Error",
  ),
  "SAM": (
    long: "Segment Anything Model",
  ),
  "TP": (
    long: "True Positive",
  ),
  "TN": (
    long: "True Negative",
  ),
  "FP": (
    long: "False Positive",
  ),
  "FN": (
    long: "False Negative",
  ),
  "DSM": (
    long: "Digital Surface Model",
  ),
  "DEM": (
    long: "Digital Elevation Model",
  ),
  "DTM": (
    long: "Digital Terrain Model",
  ),
  "nDSM": (
    long: "normalized Digital Surface Model",
  ),
  "DL": (
    long: "Deep Learning",
  ),
  "LiDAR": (
    long: "Light Detection and Ranging",
  ),
  "CNN": (
    long: "Convolutional Neural Network",
  ),
  "FCN": (
    long: "Fully Convolutional Network",
  ),
  "CRF": (
    long: "Conditional Random Field",
  ),
  "AI": (
    long: "Artificial Intelligence",
  ),
  "ViT": (
    long: "Vision Transformer",
  ),
  "GPU": (
    long: "Graphics Processing Unit",
  ),
  "IoU": (
    long: "Intersection over Union",
  ),
  "HMA": (
    long: "Hungarian Matching Algorithm",
  )
)

#let get_key(key) = {
  let matched-key = {
    for k in abbreviations.keys() {
      if k == key {
        k
      }
    }
    none
  }

  let term-data = abbreviations.at(matched-key)
  let short = matched-key
  let long = term-data.long

  (short, long)
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
