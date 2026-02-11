// Book-style page setup with alternating margins
#set page(
  width: 21cm, 
  height: 29.7cm, 
  margin: (
    inside: 3cm,   // More space for binding
    outside: 2cm,
    top: 2cm, 
    bottom: 3cm
  )
)

#set text(12pt)

// Headings
#show heading.where(level: 1): set text(size: 15pt, weight: "bold")
#show heading.where(level: 2): set text(size: 13pt, weight: "bold")
#show link: it => underline(text(fill: blue)[#it])

// ===== TITLE PAGE =====
#include "sections/titlepage.typ"
#pagebreak()

// ===== FRONT MATTER (Roman numerals) =====
#set page(
  numbering: "i",
  number-align: center + bottom,
)
#counter(page).update(1)

// Table of Contents
#outline(
  title: "Table of Contents",
  indent: auto,
)
#pagebreak()

// List of Figures
#outline(
  title: "List of Figures",
  target: figure.where(kind: image),
)
#pagebreak()

// List of Tables
#outline(
  title: "List of Tables", 
  target: figure.where(kind: table),
)
#pagebreak()

// Abstract
#include "sections/abstract.typ"
#pagebreak()

// Acknowledgements
#include "sections/acknowledgements.typ"
#pagebreak()

// AI and Ethics Statement (on one page)
#include "sections/statements.typ"
#pagebreak()

// ===== MAIN BODY =====
#set page(
  numbering: "1",
  number-align: bottom,
  header: context {
    let page-num = here().page()
    let is-odd = calc.odd(page-num)
    
    // Get current heading
    let elems = query(selector(heading.where(level: 1)).before(here()))
    let current-heading = if elems.len() > 0 {
      elems.last().body
    } else {
      []
    }
    
    if is-odd {
      // Odd pages: heading on right
      align(right)[
        #emph(current-heading)
        #h(1fr)
        #counter(page).display()
      ]
    } else {
      // Even pages: heading on left  
      align(left)[
        #counter(page).display()
        #h(1fr)
        #emph(current-heading)
      ]
    }
    
    line(length: 100%, stroke: 0.5pt)
  }
)

#counter(page).update(1)

// ===== CONTENT STARTS HERE =====
= Introduction

#lorem(100)

== Background

#lorem(80)

#figure(
  table(
    columns: 3,
    [Header 1], [Header 2], [Header 3],
    [Data 1], [Data 2], [Data 3],
    [Data 4], [Data 5], [Data 6],
  ),
  caption: [Sample table for demonstration]
)

#lorem(50)

= Methods

#lorem(120)

#figure(
  rect(width: 80%, height: 100pt, stroke: black),
  caption: [Sample figure placeholder]
)

== Data Collection

#lorem(90)

= Results

#lorem(150)

= Discussion

#lorem(130)

= Conclusion

#lorem(80)

#pagebreak()

// Bibliography
#heading(numbering: none)[References]

// Your bibliography here

#pagebreak()

// Appendix
#heading(numbering: none)[Appendix]

// Your appendix content here
