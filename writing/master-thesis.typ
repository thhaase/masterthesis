// ===== SETUP =====
#set page(
  width: 21cm, 
  height: 29.7cm, 
  margin: (
    inside: 3cm,
    outside: 2cm,
    top: 2.5cm, 
    bottom: 2.5cm
  )
)

#include "sections/0_setup.typ"

#let long-caption(width: 80%, body) = {
  align(center)[
    #block(width: width)[
      #text(size: 10pt)[
        #body
      ]
    ]
  ]
}

// ===== TITLE PAGE =====
#include "sections/1_titlepage.typ"

// ===== FRONT MATTER =====
#include "sections/2_frontmatter.typ"

// ===== MAIN BODY =====
#include "sections/3_main_body_setup.typ"

// ===== CONTENT STARTS HERE =====
= Introduction

#figure(
  image("../images/outsect.jpg", width: 30%),
  caption: [Outsect],
)<fig:label>
#long-caption[#lorem(30)]

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
#bibliography("My Library.bib")
