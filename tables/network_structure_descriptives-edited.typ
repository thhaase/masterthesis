/*
#table(
  columns: 2,
  align: (col, row) => (left,left,).at(col),
  inset: 6pt,
  [*Metric*], [*Value*],
  [Nodes],
  [29 672],
  [Links],
  [60 117],
  [Density],
  [0.0001],
  [Degree - Mean],
  [4.05],
  [Degree - Standard Deviation],
  [55.90],
  [Reciprocity],
  [0.0034],
  [Assortativity \(Degree)],
  [-0.066],
  [Average Shortest Path],
  [4.21],
  [Diameter],
  [139],
  [Clustering Coefficient],
  [0.036],
  [Max K-Core],
  [13],
  [Modularity \(Walktrap)],
  [0.498],
)
*/
#table(
  columns: (auto, 1fr, auto),
  align: (left, left + horizon, right + horizon),
  stroke: none,
  inset: (x: 8pt, y: 4pt),

  table.hline(stroke: 0.6pt),
  table.header(
    [*Category*], [*Metric*], [*Value*],
  ),
  table.hline(stroke: 0.4pt),

  table.cell(rowspan: 2)[*Size*],
  [Nodes ($n$)],                             [29,672],
  [Directed edges ($m$)],                    [60,117],

  table.hline(stroke: 0.2pt, start: 1),
  table.cell(rowspan: 3)[*Degree*],
  [Density ($rho$)],                         [$<$ 0.001],
  [Mean degree ($macron(k)$)],               [4.05],
  [SD of degree ($sigma_k$)],                [55.90],

  table.hline(stroke: 0.2pt, start: 1),
  table.cell(rowspan: 2)[*Directionality*],
  [Reciprocity],                             [0.003],
  [Degree assortativity ($r_k$)],            [#sym.minus 0.066],

  table.hline(stroke: 0.2pt, start: 1),
  table.cell(rowspan: 2)[*Distance*],
  [Average shortest path ($macron(ell)$)],   [4.21],
  [Diameter],                                [139],

  table.hline(stroke: 0.2pt, start: 1),
  table.cell(rowspan: 3)[*Cohesion*],
  [Clustering coefficient ($C$)],            [0.036],
  [Max $k$-core],                            [13],
  [Modularity (Walktrap)],                   [0.498],

  table.hline(stroke: 0.6pt),
)
