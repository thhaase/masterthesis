#set page(paper: "a4", margin: (x: 2.5cm, y: 3cm))
#set text(font: "New Computer Modern", size: 12pt)

#set par(justify: false)
#v(1fr)
#align(center)[
  #text(size: 12pt)[
    Linköping University \
    Institute for Analytical Sociology
  ]
]

#v(2cm)

#align(center)[
  #text(size: 16pt, weight: "bold")[
    Master's Thesis
  ]
]

#v(2cm)

#align(center)[
  #text(size: 14pt, weight: "bold")[
    Title
  ]  
  #v(0.5cm)
  #text(size: 14pt, weight: "bold")[
    Descriptive Subtitle
  ]
]

#v(1.5cm)

#align(center)[
  #text(size: 12pt)[
    Thomas Haase#super[\*]
  ]
]

#v(1cm)

#align(center)[
  #datetime.today().display("[day]. [month repr:long] [year]")
]

#v(1fr)

#table(
  columns: 2,
  stroke: none,
  align: (left, left),
  column-gutter: 1em,
  [First Supervisor:], [Károly Takács],
  [Second Supervisor:], [Philipp Lorenz-Spreen],
  [Examiner:], [#text(fill: red)[Examiner]],
)

#v(2cm)

#line(length: 100%, stroke: 0.5pt)

#text(size: 9pt)[
  \* \
  #h(0.5em) _E-Mail 1: thoha774\@student.liu.se_ \
  #h(0.5em) _E-Mail 2: thhaase.soz\@gmail.com_
]
