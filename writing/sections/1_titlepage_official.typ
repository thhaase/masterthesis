#set page(paper: "a4", margin: (x: 2.5cm, y: 3cm))
#set text(font: "TeX Gyre Pagella", size: 12pt)
#set par(justify: false)

// --- Top header (right-aligned, sans-serif) ---
#align(right)[
  #set text(font: "Georgia", size: 12pt)
  Linköping University | Institute for Analytical Sociology \
  Master's thesis, 30 ECTS | Computational Social Science \
  2026 | #text(fill: red)[ISRN]
]
#v(50mm)

// --- Main title block (indented ~38mm from left) ---
#pad(left: 38mm)[
  #block(width: 100%)[
    // Primary title (English)
    #text(size: 25pt, weight: "bold")[#text(fill: red)[Title]] \
    #text(size: 13pt)[#text(fill: red)[-- Descriptive Subtitle]]

    #line(length: 100%, stroke: 0.5pt)

    // Secondary title (Swedish, italic)
    #text(size: 13pt, style: "italic")[#text(fill: red)[Titel på svenska]] \
    #text(size: 13pt, style: "italic")[#text(fill: red)[-- Undertitel]]

    #v(10mm)

    #text(size: 12pt, weight: "bold")[Thomas Haase]

    #v(10mm)

    #text(size: 10pt)[
      Supervisor: Károly Takács \
      External supervisor: Philipp Lorenz-Spreen \
      Examiner: #text(fill: red)[Examiner]
    ]
  ]
]

#v(1fr)

// --- Bottom bar: logo + address (pinned to bottom) ---
#grid(
  columns: (1fr, 1fr),
  align: (left + bottom, right + bottom),
  image("../logos/liu_primary_black_en.svg", width: 85mm),
  text(size: 10pt)[
    Linköping University \
    SE--581 83 Linköping \
    +46 13 28 10 00, www.liu.se
  ],
)

