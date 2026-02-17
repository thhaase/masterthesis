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

// Base Text Setting
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

// --- Headings ---
#set heading(numbering: "1.1")

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
#set page(
  numbering: "1",
  header: context {
    // Get current heading
    let elems = query(selector(heading.where(level: 1)).before(here()))
    let current-heading = if elems.len() > 0 {
      elems.last().body
    } else {
      []
    }
    
    let page-num = here().page()
    set text(size: 10pt)
    
    if calc.odd(page-num) {
      align(right)[#emph(current-heading)] // Odd pages: heading on right
    } else {
      align(left)[#emph(current-heading)]  // Even pages: heading on left
    }
    
    v(0.3em)
    line(length: 100%, stroke: 0.5pt)
  },
  footer: context {
    let page-num = here().page()
    if calc.odd(page-num) {
      align(right)[#counter(page).display()]  // Odd: right
    } else {
      align(left)[#counter(page).display()]   // Even: left
    }
  }
)

#counter(page).update(1)


// =================================================
// ===== C O N T E N T   S T A R T S   H E R E =====
// =================================================

= Introduction
// REQUIREMENTS:
// - Overview of information presented in thesis
// - Summary of other sections in order (lit review, methods, findings, conclusions)
//    - What are key literatures/theoretical perspectives
//    - Which methods are used?
//    - What are main findings and conclusions?
// - Start broad with relevance statement 
// - Narrow to specific research question & findings

#figure(
  image("../images/outsect.jpg", width: 30%),
  caption: [Outsect],
)<fig:label>
#long-caption[#lorem(30)]


= Literature Review
// REQUIREMENTS:
// - Demonstrate deep knowledge of and clear contribution to a topical social science field
// - Overview of field: whether, how and to what extent previous research addressed your research question
// - How thesis contributes to existing work in field (identify gap)
// - Start broad
//    - theoretical paradigms
// - Narrow down
//    - student's hypothesis to be tested
// - Introduce relevant variables as concepts
// - Describe case study in detail




= Data and Methods
// REQUIREMENTS:
// - Description of data
//    - how it was obtained, populations, sampling strategies
// - Link variables to concepts
// - Shortcomings of data with impacts on results
// - Tables of descriptive statistics derived from data
// - Overview of methods used
//    - Logic behind choice of method (why is it the best way to answer the question?)
//    - Discussion of method's weaknesses
//    - Model specifications (equations, algorithms)
//    - Figures that clarify approach
//    - Cite packages used

Data were collected via Twitter's streaming API using two parallel strategies to capture reply interactions involving German MPs. The follow stream tracked replies to MP-generated tweets. The track stream captured tweets mentioning MP handles (e.g., "\@username"), including direct replies and nested replies to reconstruct complete conversation threads. Protected accounts were excluded. Both datasets were combined and deduplicated to create the final reply dataset.


- Hat armin den Datensatz schonmal irgendwo verwendet, sodass ich ihn zitieren könnte?

1. First write this data collection section, send to armin for refinement and clarification purposes.
2. write a refined proposal that focuses on politicians as egonets
==> look in data where politicians are in reply network. make sure to filter first ofr ONLY the trees coming from politicians

= Results
// REQUIREMENTS:
// - Describe output of each stage
// - Analog to lab notes: stating each stage of analysis + results with relevant figures/tables
// - Simple direct interpretations of each analysis
//    - Explain how each relates to the relevant hypothesis or research question
//    - Note any disagreements


= Discussion
// REQUIREMENTS:
// - How do findings taken together provide support/evidence for hypothesis/theoretical perspectives
// - Speaks to approaches of literature review section
//    - How was the gap filled?
//    - What side do the results support? Is there more than one side?
//    - What future work needs to be done


= Conclusion
// REQUIREMENTS:
// - Inverse of introduction: 
//    - starts narrow (answering the final question)
//    - broadens to larger social or scientific relevance
// - Should contain a discussion of broader meaning and significance of findings








// =================================================
#pagebreak()

// ===== APPENDICES =====
#set heading(numbering: none)

= Appendix A: Additional Tables and Figures

#lorem(50)

#pagebreak()

= Appendix B: Code
// REQUIRED: Must contain code used to process datasets for examination

```python
# Example: Data cleaning code
import pandas as pd
import numpy as np

# Load data
df = pd.read_csv('data.csv')

# Data processing steps
# ...
```

#pagebreak()

= Appendix C: Prompts
// Example: If you used surveys, include the questionnaire

#lorem(100)

#pagebreak()

// ===== BIBLIOGRAPHY =====
#bibliography(
  "My Library.bib", 
  style: "american-sociological-association"
)
