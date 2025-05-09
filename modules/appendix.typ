#import "@preview/subpar:0.2.0"

= Supplementary Material Images

#heading(depth: 5, numbering: none, bookmarked: false)[Filtered Input Data]
#subpar.grid(
  columns: 2,
  gutter: 0mm,
  image("../figures/input/result.png"),
  caption: [
    100 images evenly sampled from the input data
  ],
  label: <fig:input:result>,
)
#heading(depth: 5, numbering: none, bookmarked: false)[Filtered by area]
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  image("../figures/input/removal/area1.png"),
  image("../figures/input/removal/area2.png"),
  caption: [
    Input data removed by area
  ],
  label: <fig:remove:area>,
)
#heading(depth: 5, numbering: none, bookmarked: false)[Filtered by overlapping parts]
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  image("../figures/input/removal/parts1.png"),
  image("../figures/input/removal/parts2.png"),
  image("../figures/input/removal/parts3.png"),
  caption: [
    Input data removed by overlapping parts
  ],
  label: <fig:remove:parts>,
)

#heading(depth: 5, numbering: none, bookmarked: false)[Filtered by confidence]
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  image("../figures/input/removal/confidence1.png"),
  image("../figures/input/removal/confidence2.png"),
  image("../figures/input/removal/confidence3.png"),
  caption: [
    Input data removed by size
  ],
  label: <fig:remove:size>,
)
#heading(depth: 5, numbering: none, bookmarked: false)[Filtered by bounding box]
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  image("../figures/input/removal/bbox1.png"),
  image("../figures/input/removal/bbox2.png"),
  caption: [
    Input data removed by bounding box percentage
  ],
  label: <fig:remove:bbox>,
)

#heading(depth: 5, numbering: none, bookmarked: false)[Filtered by flat roof only]
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  image("../figures/input/removal/flat1.png"),
  image("../figures/input/removal/flat2.png"),
  image("../figures/input/removal/flat3.png"),
  image("../figures/input/removal/flat4.png"),
  image("../figures/input/removal/flat5.png"),
  image("../figures/input/removal/flat6.png"),
  caption: [
    Input data removed by flat roof only
  ],
  label: <fig:remove:flat>,
)



#pagebreak()
#heading(depth: 5, numbering: none, bookmarked: false)[SAM Results]
#subpar.grid(
  columns: 4,
  gutter: 1mm,
  figure(image("../data/6/0/sam/best/mask.png")),
  figure(image("../data/6/0/sam/best/generated.png")),
  figure(image("../data/6/0/sam/best/filtered.png")),
  figure(image("../data/6/0/sam/best/dilated.png")),
  figure(image("../data/6/1/sam/best/mask.png")),
  figure(image("../data/6/1/sam/best/generated.png")),
  figure(image("../data/6/1/sam/best/filtered.png")),
  figure(image("../data/6/1/sam/best/dilated.png")),
  figure(image("../data/6/2/sam/best/mask.png")),
  figure(image("../data/6/2/sam/best/generated.png")),
  figure(image("../data/6/2/sam/best/filtered.png")),
  figure(image("../data/6/2/sam/best/dilated.png")),
  figure(image("../data/6/3/sam/best/mask.png")),
  figure(image("../data/6/3/sam/best/generated.png")),
  figure(image("../data/6/3/sam/best/filtered.png")),
  figure(image("../data/6/3/sam/best/dilated.png")),
  figure(image("../data/6/4/sam/best/mask.png")),
  figure(image("../data/6/4/sam/best/generated.png")),
  figure(image("../data/6/4/sam/best/filtered.png")),
  figure(image("../data/6/4/sam/best/dilated.png")),
  figure(image("../data/6/5/sam/best/mask.png")),
  figure(image("../data/6/5/sam/best/generated.png")),
  figure(image("../data/6/5/sam/best/filtered.png")),
  figure(image("../data/6/5/sam/best/dilated.png")),
  outlined: false,
)
#subpar.grid(
  columns: 4,
  gutter: 1mm,
  figure(image("../data/6/6/sam/best/mask.png")),
  figure(image("../data/6/6/sam/best/generated.png")),
  figure(image("../data/6/6/sam/best/filtered.png")),
  figure(image("../data/6/6/sam/best/dilated.png")),
  figure(image("../data/6/7/sam/best/mask.png")),
  figure(image("../data/6/7/sam/best/generated.png")),
  figure(image("../data/6/7/sam/best/filtered.png")),
  figure(image("../data/6/7/sam/best/dilated.png")),
  figure(image("../data/6/8/sam/best/mask.png")),
  figure(image("../data/6/8/sam/best/generated.png")),
  figure(image("../data/6/8/sam/best/filtered.png")),
  figure(image("../data/6/8/sam/best/dilated.png")),
  figure(image("../data/6/9/sam/best/mask.png")),
  figure(image("../data/6/9/sam/best/generated.png")),
  figure(image("../data/6/9/sam/best/filtered.png")),
  figure(image("../data/6/9/sam/best/dilated.png")),
  outlined: false,
)
#subpar.grid(
  columns: 4,
  gutter: 1mm,
  figure(image("../data/6/10/sam/best/mask.png")),
  figure(image("../data/6/10/sam/best/generated.png")),
  figure(image("../data/6/10/sam/best/filtered.png")),
  figure(image("../data/6/10/sam/best/dilated.png")),
  figure(image("../data/6/11/sam/best/mask.png")),
  figure(image("../data/6/11/sam/best/generated.png")),
  figure(image("../data/6/11/sam/best/filtered.png")),
  figure(image("../data/6/11/sam/best/dilated.png")),
  figure(image("../data/6/12/sam/best/mask.png")),
  figure(image("../data/6/12/sam/best/generated.png")),
  figure(image("../data/6/12/sam/best/filtered.png")),
  figure(image("../data/6/12/sam/best/dilated.png")),
  figure(image("../data/6/13/sam/best/mask.png")),
  figure(image("../data/6/13/sam/best/generated.png")),
  figure(image("../data/6/13/sam/best/filtered.png")),
  figure(image("../data/6/13/sam/best/dilated.png")),
  figure(image("../data/6/19/sam/best/mask.png")),
  figure(image("../data/6/19/sam/best/generated.png")),
  figure(image("../data/6/19/sam/best/filtered.png")),
  figure(image("../data/6/19/sam/best/dilated.png")),
  outlined: false,
)
#subpar.grid(
  columns: 4,
  gutter: 1mm,
  figure(image("../data/6/14/sam/best/mask.png")),
  figure(image("../data/6/14/sam/best/generated.png")),
  figure(image("../data/6/14/sam/best/filtered.png")),
  figure(image("../data/6/14/sam/best/dilated.png")),
  figure(image("../data/6/15/sam/best/mask.png")),
  figure(image("../data/6/15/sam/best/generated.png")),
  figure(image("../data/6/15/sam/best/filtered.png")),
  figure(image("../data/6/15/sam/best/dilated.png")),
  figure(image("../data/6/16/sam/best/mask.png")),
  figure(image("../data/6/16/sam/best/generated.png")),
  figure(image("../data/6/16/sam/best/filtered.png")),
  figure(image("../data/6/16/sam/best/dilated.png")),
  figure(image("../data/6/17/sam/best/mask.png")),
  figure(image("../data/6/17/sam/best/generated.png")),
  figure(image("../data/6/17/sam/best/filtered.png")),
  figure(image("../data/6/17/sam/best/dilated.png")),
  figure(image("../data/6/18/sam/best/mask.png")),
  figure(image("../data/6/18/sam/best/generated.png")),
  figure(image("../data/6/18/sam/best/filtered.png")),
  figure(image("../data/6/18/sam/best/dilated.png")),
  numbering: (..nums) => [#counter(figure.where(outlined: true)).display((..num_figs)=>num_figs.pos().at(0))],
  caption: [
    Best SAM results for mask, generated, filtered and dilated
  ],
  label: <fig:appendix:sam:results>,
)

#subpar.grid(
  columns: 1,
  gutter: 0mm,
  box(figure(image("../data/6/1/sam/filtered/masks.png")), clip: true, width: 100%, inset: (bottom: -17.4in)),
  outlined: false,
)
#subpar.grid(
  columns: 1,
  gutter: 0mm,
  box(figure(image("../data/6/19/sam/filtered/masks.png")), clip: true, width: 100%, inset: (bottom: -20.4in)),
  caption: [
    SAM resulting best masks for each image and segment
  ],
  numbering: (..nums) => [#counter(figure.where(outlined: true)).display((..num_figs)=>num_figs.pos().at(0))],
  label: <fig:sam:filtered:masks2>,
)



= Supplementary Material Source Code
#heading(depth: 5, numbering: none, bookmarked: false)[Strategy Base Class]
```python
class Strategy:
  def __init__(self, n=None, m=None):
    self.n = n
    self.m = m

  def get_points(self, surfaces):
    raise NotImplementedError("Subclasses must implement get_points")

  # Base implementation simply adding every point as positive
  def get_sam_inputs(self, surfaces):
    # Get input points from current strategies implementation
    input_point_lists = self.get_points(surfaces)

    # Initialise empty lists
    input_points = []
    input_label = []

    for i, input_points_per_surface in enumerate(input_point_lists):
      # Predefine structures
      current_points = np.empty((0, 2), dtype=int)
      current_label = np.empty(0, dtype=int)

      for row, col in input_points_per_surface:
        current_points = np.append(current_points, [[col, row]], axis=0)
        current_label = np.append(current_label, [1])

      input_points.append(current_points)
      input_label.append(current_label)

    return input_points, input_label

  def is_non_edge_point(self, row, col, surface):
    # Check if point is in surface
    if (row, col) not in surface:
      return False
    # If any neighbour is not in surface this is an edge
    for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
      if (row + dr, col + dc) not in surface:
        return False

    return True
```

#heading(depth: 5, numbering: none, bookmarked: false)[Random Point Strategy]
```python
class Random(Strategy):
  def __init__(self, n=1):
    super().__init__(n=n, m=None)

  def get_points(self, surfaces):
    points = []
    for surface in surfaces:
      current_points = []

      # Find all valid points
      valid_points = []
      for row, col in surface:
        if self.is_non_edge_point(row, col, surface):
          valid_points.append((row, col))

      # Append n valid points
      for _ in range(self.n):
        if not valid_points:
          break
        random_index = random.randint(0, len(valid_points) - 1)
        current_points.append(valid_points[random_index])
        valid_points.pop(random_index)
      points.append(current_points)

    return points
```

#heading(depth: 5, numbering: none, bookmarked: false)[Center Point Strategy]
```python
class Center(Strategy):
  def __init__(self, n=1):
    super().__init__(n=n, m=None)

  def get_points(self, surfaces):
    points = []
    for surface in surfaces:
      rows, cols = zip(*surface)
      if rows and cols:
        # Bounds
        min_row, max_row = min(rows), max(rows)
        min_col, max_col = min(cols), max(cols)

        # Calculate row, column grid from n
        num_rows = int(np.sqrt(self.n))
        num_cols = int(np.ceil(self.n / num_rows))

        # Step size
        rs = 1 / (num_rows + 1)
        cs = 1 / (num_cols + 1)

        current_points = []
        for r in np.linspace(0, 1, num_rows + 2)[1:-1]:
          for c in np.linspace(0, 1, num_cols + 2)[1:-1]:
            # Define current grid cell boundaries
            cr_min = int(min_row + (max_row - min_row) * (r - rs / 2))
            cr_max = int(min_row + (max_row - min_row) * (r + rs / 2))
            cc_min = int(min_col + (max_col - min_col) * (c - cs / 2))
            cc_max = int(min_col + (max_col - min_col) * (c + cs / 2))

            # Calculate frequency distribution for the current grid cell
            freq_r = {}
            freq_c = {}
            for row, col in surface:
              if cr_min <= row <= cr_max and cc_min <= col <= cc_max:
                freq_r[row] = freq_r.get(row, 0) + 1
                freq_c[col] = freq_c.get(col, 0) + 1

            # Weighted average for center_row within the grid cell
            wrs = sum(row * freq for row, freq in freq_r.items())
            center_row = int(wrs / sum(freq_r.values()))

            # Weighted average for center_col within the grid cell
            wcs = sum(col * freq for col, freq in freq_c.items())
            center_col = int(wcs / sum(freq_c.values()))
            
            # If the current point is valid, append it
            if self.is_non_edge_point(center_row, center_col, surface):
              current_points.append((center_row, center_col))
            else:
              # If not in surface, move to closest surface point
              if (center_row, center_col) not in surface:
                closest_point = None
                min_dist = float('inf')
                for row, col in surface:
                  x = (row - center_row)**2 + (col - center_col)**2
                  d = np.sqrt(x)
                  if d < min_dist:
                    min_dist = d
                    closest_point = (row, col)
                center_row, center_col = closest_point

              # Search for a valid adjacent point iteratively
              queue = [(center_row, center_col)]
              visited = set()
              while queue:
                row, col = queue.pop(0)

                if self.is_non_edge_point(row, col, surface):
                  current_points.append((row, col))
                  break

                visited.add((row, col))
                # Add unvisited neighbors to the queue
                for dr, dc in [(0, 1), (0, -1), (1, 0), (-1, 0)]:
                  nr = row + dr
                  nc = col + dc

                  if (nr, nc) in surface and (nr, nc) not in visited:
                    queue.append((nr, nc))
        points.append(current_points)

    # Remove duplicates
    points = [list(set(point_list)) for point_list in points]
    return points
```

#heading(depth: 5, numbering: none, bookmarked: false)[Combined Strategy]
```python
class Combined(Strategy):
  def __init__(self, n=3, m=10):
    super().__init__(n, m)

  def get_sam_inputs(self, surfaces):
    positive_points_list = Center(n=self.n).get_points(surfaces)
    negative_points_list = Center(n=1).get_points(surfaces)

    input_points, input_label = [], []
    # Positive points
    for i, positive_points in enumerate(positive_points_list):
      current_points = np.empty((0, 2), dtype=int)
      current_labels = np.empty(0, dtype=int)
      for row, col in positive_points:
        current_points = np.append(current_points, [[col, row]], axis=0)
        current_labels = np.append(current_labels, [1])

      # Negative points
      added_negatives = 0
      for j, negative_points in enumerate(negative_points_list):
        if i != j and negative_points:
          row, col = negative_points[0]
          current_points = np.append(current_points, [[col, row]], axis=0)
          current_labels = np.append(current_labels, [0])

          added_negatives += 1
          if added_negatives >= self.m:
            break

      input_points.append(current_points)
      input_label.append(current_labels)

    return input_points, input_label
```







#pagebreak()
#heading(depth: 5, numbering: none, bookmarked: false)[Surface Growth]
```python
# STEP 1: INITIAL SURFACE GROWTH
def calculate_initial_surfaces(edges):
  surfaces = []
  visited = np.zeros_like(edges, dtype=bool)
  visited[edges != 0] = True

  for row in range(edges.shape[0]):
    for col in range(edges.shape[1]):
      if not edges[row, col] and not visited[row, col]:
        surface = []
        stack = [(row, col)]

        while stack:
          r, c = stack.pop()
          if (
            0 <= r < edges.shape[0]
            and 0 <= c < edges.shape[1]
            and not edges[r, c]
            and not visited[r, c]
          ):
            visited[r, c] = True
            surface.append((r, c))

            stack.extend([
              (r + 1, c),
              (r - 1, c),
              (r, c + 1),
              (r, c - 1),
            ])
        if surface:
          surfaces.append(surface)

  return surfaces
```

#heading(depth: 5, numbering: none, bookmarked: false)[Separation]
```python
def separation(surfaces, edges):
  results = []
  for surface in surfaces:
    # Separate edge and inner pixels
    inner_pixels = [
      (r, c) for r, c in surface
      if (
        1 <= r < edges.shape[0] - 1
        and 1 <= c < edges.shape[1] - 1
        and not edges[r - 1, c]
        and not edges[r + 1, c]
        and not edges[r, c - 1]
        and not edges[r, c + 1]
      )
    ]
    edge_pixels = [
      (r, c) for r, c in surface
      if (r, c) not in inner_pixels
    ]

    # Split disconnected inner pixel regions
    separated = []
    if inner_pixels:
      mask = np.zeros_like(edges, dtype=bool)
      for r, c in inner_pixels:
        mask[r, c] = True

      labeled_array, num_features = ndimage_label(mask)
      split_surfaces = [
        [(r, c) for r, c in np.argwhere(labeled_array == label_num)]
        for label_num in range(1, num_features + 1)
      ]
      separated.extend(split_surfaces)

      # Reassign edge pixel
      unassigned = edge_pixels[:]
      while unassigned:
        assigned = {}
        for pixel in unassigned:
          for i, split_surface in enumerate(split_surfaces):
            for r, c in split_surface:
              if abs(pixel[0] - r) <= 1 and abs(pixel[1] - c) <= 1:
                assigned[pixel] = i
                break
            else:
              continue
            break

        # Apply assignments
        assigned_here = []
        for pixel, i in assigned.items():
          separated[len(separated) - len(split_surfaces) + i].append(pixel)
          assigned_here.append(pixel)

        # Remove newly assigned from unassgined
        unassigned = [p for p in unassigned if p not in assigned_here]
        # If for some reason no new assignment was made
        if not assigned_here:
          break
      # Add all unadded as one coherent surface
      if unassigned:
        separated.extend([[pixel] for pixel in unassigned])
    else:
      if edge_pixels:
        # If only edge pixels, add them as a separate surface
        separated.append(edge_pixels)
    # For the current surface, add a list of all separations from it
    results.append(separated)
  return results
```


#heading(depth: 5, numbering: none, bookmarked: false)[Relink]
```python
# STEP 3: RELINKING BASED ON SIMILAR DERIVATIVE AVERAGES
def relink(surfaces, data, threshold):
  surface_derivatives = []
  for surface in surfaces:
    x = [data['x']['clipped'][row, col] for row, col in surface]
    y = [data['y']['clipped'][row, col] for row, col in surface]

    derivatives = {
      'surface': surface,
      'x_avg': np.median(x),
      'y_avg': np.median(y)
    }
    surface_derivatives.append(derivatives)

  # Group surfaces based on derivatives
  groups = []
  for surface_data in surface_derivatives:
    found = False
    for group in groups:
      for existing in group:
        if (abs(surface_data['x_avg'] - existing['x_avg']) <= threshold and
            abs(surface_data['y_avg'] - existing['y_avg']) <= threshold):
          group.append(surface_data)
          found = True
          break
      if found:
        break
    # Create new group
    if not found:
      groups.append([surface_data])

  # Merge surfaces within each group
  merged = []
  for group in groups:
    merged_surface = []
    for surface in group:
      merged_surface.extend(surface['surface'])
    merged.append(merged_surface)

  results = []
  for surface in merged:
    mask = np.zeros_like(data['combined_edges'], dtype=bool)
    for row, col in surface:
      mask[row, col] = True
    labeled_mask, num_features = ndimage_label(mask)
    if num_features > 1:
      for label in range(1, num_features + 1):
        surface = [(r, c) for r, c in np.argwhere(labeled_mask == label)]
        results.append(surface)
    else:
      results.append(surface)

  return results
```