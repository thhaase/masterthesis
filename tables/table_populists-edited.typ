/*
#table(
  columns: 3,
  [**Variable**], [**Mean / n**], [**Standard\ Deviation**],
  [Populism score],   [1.03], [1.35],
  [People score],     [0.36], [0.29],
  [Elite score],      [-0.50],[0.34],
  [Antagonism score], [0.80], [0.68],
  [AfD],   [6], [--],
  [BSW],   [1], [--],
  [Linke], [2], [--],
  [SPD],   [1], [--],
)
*/
#grid(
  columns: (1.2fr, 1.2fr),
  column-gutter: 16pt,

  // === LEFT: continuous descriptives ===
  table(
    columns: (auto, 1fr, 1fr),
    align: (left, right + horizon, right + horizon),
    stroke: none,
    inset: (x: 8pt, y: 4pt),

    table.hline(stroke: 0.6pt),
    table.header(
      [*Score*], [*Mean*], [*SD*],
    ),
    table.hline(stroke: 0.4pt),

    [Populism],    [1.03],            [1.35],
    [People],      [0.36],            [0.29],
    [Elite],       [#sym.minus 0.50], [0.34],
    [Antagonism],  [0.80],            [0.68],

    table.hline(stroke: 0.6pt),
  ),

  // === RIGHT: party counts ===
  table(
    columns: (auto, auto),
    align: (left, right + horizon),
    stroke: none,
    inset: (x: 8pt, y: 4pt),

    table.hline(stroke: 0.6pt),
    table.header(
      [*Party*], [*$n$*],
    ),
    table.hline(stroke: 0.4pt),

    [AfD],        [6],
    [BSW],        [1],
    [Die Linke],  [2],
    [SPD],        [1],
    //table.hline(stroke: 0.2pt),
    //[*Total*],    [*10*],

    table.hline(stroke: 0.6pt),
  ),
)