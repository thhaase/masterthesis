// ===== FRONT MATTER =====
// roman page numbering
#set page(
  numbering: "i",
  number-align: center + bottom,
  header: none,
)
#counter(page).update(1)

// Table of Contents
#align(center)[
  #text(size: 16pt, weight: "bold")[Contents]
]
#v(1em)

#outline(
  title: none,
  indent: 2em,
  depth: 3,
)
#pagebreak()

// List of Figures
#align(center)[
  #text(size: 16pt, weight: "bold")[List of Figures]
]
#v(1em)
#outline(
  title: none,
  target: figure.where(kind: image),
)
#pagebreak()

// List of Tables
#align(center)[
  #text(size: 16pt, weight: "bold")[List of Tables]
]
#v(1em)
#outline(
  title: none,
  target: figure.where(kind: table),
)
#pagebreak()

// Abstract
#include "./2.1_abstract.typ"
#pagebreak()
