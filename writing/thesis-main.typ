// Book-style page setup with alternating margins
#set page(
  width: 21cm, 
  height: 29.7cm, 
  margin: (
    inside: 3cm,   // More space for binding
    outside: 2cm,
    top: 2.5cm, 
    bottom: 2.5cm
  )
)

// Use serif font matching the original
#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en"
)

// Paragraph settings
#set par(
  justify: true,
  leading: 0.65em,
  first-line-indent: 0em
)

// Headings - matching the original style
#show heading.where(level: 1): it => {
  pagebreak(weak: true)
  v(1em)
  text(size: 16pt, weight: "bold")[#counter(heading).display() #it.body]
  v(0.5em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 14pt, weight: "bold")[
    #counter(heading).display() #it.body
  ]
  v(0.4em)
}

#show heading.where(level: 3): it => {
  v(0.6em)
  text(size: 12pt, weight: "bold")[
    #counter(heading).display() #it.body
  ]
  v(0.3em)
}

#show link: it => underline(text(fill: blue)[#it])

// ===== TITLE PAGE =====
#include "bachelorthesis.typ"
#pagebreak()

// Blank page after title
#page(numbering: none)[]

// ===== FRONT MATTER (Roman numerals) =====
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

// List of Figures (if you have figures)
// #align(center)[
//   #text(size: 16pt, weight: "bold")[List of Figures]
// ]
// #v(1em)
// #outline(
//   title: none,
//   target: figure.where(kind: image),
// )
// #pagebreak()

// List of Tables (if you have tables)
// #align(center)[
//   #text(size: 16pt, weight: "bold")[List of Tables]
// ]
// #v(1em)
// #outline(
//   title: none,
//   target: figure.where(kind: table),
// )
// #pagebreak()

// Abstract
#include "sections/abstract.typ"
#pagebreak()

// ===== MAIN BODY =====
#set page(
  numbering: "1",
  header: context {
    let page-num = here().page()
    
    // Get current heading
    let elems = query(selector(heading.where(level: 1)).before(here()))
    let current-heading = if elems.len() > 0 {
      elems.last().body
    } else {
      []
    }
    
    set text(size: 10pt)
    if calc.odd(page-num) {
      // Odd pages: number on right, heading on left
      grid(
        columns: (1fr, 1fr),
        align: (left, right),
        [#emph(current-heading)],
        [#counter(page).display()]
      )
    } else {
      // Even pages: number on left, heading on right
      grid(
        columns: (1fr, 1fr),
        align: (left, right),
        [#counter(page).display()],
        [#emph(current-heading)]
      )
    }
    
    v(0.3em)
    line(length: 100%, stroke: 0.5pt)
  }
)

#counter(page).update(1)

// ===== CONTENT STARTS HERE =====
= Introduction

#lorem(100)

== Background

#lorem(80)

= Theory

== Introduction

#lorem(50)

== The background to academic capitalism

#lorem(100)

= State of Research

#lorem(80)

= Method

#lorem(120)

= Results

#lorem(150)

= Discussion and Conclusion

#lorem(130)

#pagebreak()

// ===== APPENDIX =====
#set heading(numbering: none)

= Appendix

#lorem(100)

#pagebreak()

// ===== BIBLIOGRAPHY =====
= Bibliography

// Your bibliography here
// You can use #bibliography("references.bib") if you have a .bib file

#lorem(50)
