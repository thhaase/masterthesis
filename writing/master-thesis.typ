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
  text(size: 16pt, weight: "bold")[
    #if it.numbering != none { counter(heading).display() } #it.body
  ]
  v(0.5em)
}

#show heading.where(level: 2): it => {
  v(0.8em)
  text(size: 14pt, weight: "bold")[
    #if it.numbering != none { counter(heading).display() } #it.body
  ]
  v(0.4em)
}


#show link: it => underline(text(fill: blue)[#it])
#show figure.caption: set text(size: 10pt)
#let long-caption(width: 80%, body) = {
  v(-0.6em)
  align(center)[
    #block(width: width)[
      #text(size: 10pt)[
        #body
      ]
    ]
  ]
}


// DIVIDING SECTION WORDS TOOL
// https://thhaase.github.io/academic-text-wordbudget-planner/
//

// ===== TITLE PAGE =====
#include "sections/1_titlepage_official.typ"

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

// Introduction                     [1,110w, 2.1 pages, ~10%]
// Motivation & Relevance Statement [280w, 0.5p]
// Research Question                [280w,0.5p]
// Summary of other Sections (Basically summary of Introduction Paragraphs)                         [550w - 1 page]

== Motivation & Relevance Statement [280w, 0.5p]
#lorem(280)

== Research Question                [280w,0.5p]
#lorem(280)

== Summary of other Sections (Basically summary of Introduction Paragraphs)                         [550w - 1 page]
#lorem(550)

#v(1cm)


Question:
How does the usage of populist rhetoric by german Members of Parliament on Twitter affect the politicians engagement communities?

H1: German MPs who use populist rhetoric have more strongly interconnected alters in their reply ego networks than those who do not.
  - linguistic construction of in/outgroup 
  - hyping the ingroup --> selfselection effect keeps only engaged users with knowledge of groups social facts that actively reply to each other

- In results part:
  - In exploratory analysis, we operationalized alter disconnectedness as the fragmentation ratio (number of components divided by number of alters). Results mirror the main finding: lower fragmentation — i.e., more cohesive alter networks — is associated with populist rhetoric (OR = 0.02, p = .017).
  - Exploratory analysis using the fragmentation ratio (components / alters) corroborates this pattern. Populist MPs' reply networks are structurally more cohesive — their alters cluster into fewer, larger communities rather than responding in isolation (OR = 0.02, p = .017). This is consistent with the theoretical expectation that populist rhetoric fosters a sense of shared group identity among respondents, encouraging mutual engagement beyond dyadic replies to the politician.

H2: Do Populist MPs share more audience with each other than with non-populist MPs? 

H3: What Network Structures are indicative of Populist MPs ego networks?




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


// Literature Review                    [2 740w, 5.2pages, 25%]

// Introduction                        [100w, 0.2page]
// Theoretical Background (start broad) [650w, 1.2 pages]
// Relevant Theory (less broad)         [680w, 1.3 pages]
// Case Study (detailed)                [670w, 1.3 pages]
// Hypothesis (narrow down)             [500w, 1page]
// Summary                             [100w, 0.2 page]

== Introduction                        [100w, 0.2page]
#lorem(100)

== Theoretical Background (start broad) [650w, 1.2 pages]
#lorem(650)

== Relevant Theory (less broad)         [680w, 1.3 pages]
#lorem(680)

== Case Study (detailed)                [670w, 1.3 pages]
#lorem(670)

== Hypothesis (narrow down)             [500w, 1page]
#lorem(500)

== Summary                             [100w, 0.2 page]
#lorem(100)


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


// Data & Methods                                       [1600w, 3p]

// Introduction                                        [100w, 0.2p]
// Dataset Sampling & Description                       [264w, 0.5p] 
// Operationalization & Measure                         [500w. 1p]
// Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p]
// Networkanalysis (Threads, Replynetwork, Egonetworks) [295w, 0.6p]	
// Summary                                             [100w, 0.2 p]


== Introduction                                        [100w, 0.2p]
#lorem(100)

== Dataset Sampling & Description                       [264w, 0.5p] 
#lorem(264)

Data were collected via Twitter's streaming API using two parallel strategies to capture reply interactions involving German MPs. The follow stream tracked replies to MP-generated tweets. The track stream captured tweets mentioning MP handles (e.g., "\@username"), including direct replies and nested replies to reconstruct complete conversation threads. Protected accounts were excluded. Both datasets were combined and deduplicated to create the final reply dataset.

== Operationalization & Measure                         [500w. 1p]
#lorem(500)

== Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p]
#lorem(332)

== Networkanalysis (Threads, Replynetwork, Egonetworks) [295w, 0.6p]	
#lorem(295)

== Summary                                             [100w, 0.2 p]
#lorem(100)



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

// Results                           [3320w, 6.3p]

// Introduction                     [100w, 0.2p]
// Textanalysis: Result              [510w, 1p]
// Network: Descriptives & Structure [469w, 0.9p]
// Network: Hierarchy Deepdive	     [386w, 0.7p]
// Network: Egonetworks	             [457w, 0.9p]	
// H1: Model/Means	                 [767w, 1.5p]
// HX: Deepdive??	                   [531w, 1.0p]	
// Summary                          [100w, 0.2 p]



== Introduction                     [100w, 0.2p]
#lorem(100)

== Textanalysis: Result              [510w, 1p]
The text
#figure(
  image("../images/prompt-validation-pairwise-accuracy.png", width: 100%),
  caption: [Prompt Performance - Pairwise accuracy for all expert-expert and LLM-expert rater combinations across anti-elitism and people-centrism.]
)<fig:prompt-accuracy>
#long-caption[
  Pairwise accuracy between binarized Qwen3-235B-A22B-Instruct-2507-FP8
  ratings using the developed populism system prompt and five expert
  annotators from the PopBERT training corpus @erhard2025.
  Each point represents one rater pair (expert-expert or LLM-expert).
  LLM ratings were collapsed from a 7-level Likert scale to binary
  scores (anti-elitism: score < 0; people-centrism: score > 0).
]

#figure(
  image("../images/prompt-validation-pairwise-f1-no-labs.png", width: 100%),
  caption: [Prompt Performance - Pairwise F1 scores for all expert-expert and LLM-expert rater combinations across anti-elitism and people-centrism.]
)<fig:prompt-f1>
#long-caption[
  Pairwise F1 scores between binarized Qwen3-235B-A22B-Instruct-2507-FP8
  ratings using the developed populism system prompt and five expert
  annotators from the PopBERT training corpus @erhard2025.
  Each point represents one rater pair (expert-expert or LLM-expert).
  LLM ratings were collapsed from a 7-level Likert scale to binary
  scores (anti-elitism: score < 0; people-centrism: score > 0).
]
While the F1 score is not symetric for swapping labels #link(<sec:app-symetry-of-f1-score>)[it is symetric for swapping raters].

#figure(
  image("../images/populism_dimensions_person_level.png", width: 90%),
  caption: [Title of the Figure]
)<fig:label>

#figure(
  image("../images/populism_dimensions_person_level_politicians_inset.png", width: 100%),
  caption: [Title of the Figure],
)<fig:label>

#lorem(510)
== Network Analysis

== Network: Descriptives & Structure [469w, 0.9p]
#lorem(469)

== Network: Hierarchy Deepdive	     [386w, 0.7p]
#lorem(386)

== Network: Egonetworks	             [457w, 0.9p]	
#lorem(457)

== H1: Model/Means	                 [767w, 1.5p]
#lorem(767)

== HX: Deepdive??	                   [531w, 1.0p]	
#lorem(531)

== Summary                          [100w, 0.2 p]
#lorem(100)




= Discussion
// REQUIREMENTS:
// - How do findings taken together provide support/evidence for hypothesis/theoretical perspectives
// - Speaks to approaches of literature review section
//    - How was the gap filled?
//    - What side do the results support? Is there more than one side?
//    - What future work needs to be done

// Discussion                                           [1,700w, 3.2p]	

// Introduction                                        [100w, 0.2p]
// Summary of Results	                                  [347w, 0.7p]
// Interpretation (Relate Results to Literature Review)	[387w,	0.7p]
// Implications (e.g. Significance of Findings, What side is supported, Gap filled)	[372w, 0.7p]
// Limitations & Future Work	                          [394w, 0.8p]
// Summary                                             [100w, 0.2 p]



== Introduction                                        [100w, 0.2p]
#lorem(100)

== Summary of Results	                                  [347w, 0.7p]
#lorem(347)

== Interpretation (Relate Results to Literature Review)	[387w,	0.7p]
#lorem(387)

== Implications (e.g. Significance of Findings, What side is supported, Gap filled)	[372w, 0.7p]
#lorem(372)

== Limitations & Future Work	                          [394w, 0.8p]
#lorem(394)

== Summary                                             [100w, 0.2 p]
#lorem(100)


= Conclusion
// REQUIREMENTS:
// - Inverse of introduction: 
//    - starts narrow (answering the final question)
//    - broadens to larger social or scientific relevance
// - Should contain a discussion of broader meaning and significance of findings

// Conclusion [538w, 1.0p]	
#lorem(538)

// =================================================
#pagebreak()

// ===== APPENDICES =====
#set heading(numbering: none)

= Appendix A: Additional Tables, Figures and Equations

== Symetry of F1 Score for swapping raters
<sec:app-symetry-of-f1-score>

Given binary ratings $a_i, b_i in {0, 1}$ from two raters, define:

$ "both_positive" = sum_i a_i b_i $
$ "only"_b_"positive" = sum_i (1 - a_i) b_i $
$ "only"_a_"positive" = sum_i a_i (1 - b_i) $

Treating $A$ as ground truth:

$ "precision" = "both_positive" / ("both_positive" + "only"_b_"positive"), quad
  "recall" = "both_positive" / ("both_positive" + "only"_a_"positive") $

Swapping roles swaps $"only"_a_"positive" <-> "only"_b_"positive"$,
which swaps precision and recall. Since $F_1$ is their harmonic mean:

$ F_1 = frac(2 dot "precision" dot "recall", "precision" + "recall")
      = frac(2 dot "recall" dot "precision", "recall" + "precision")$

Multiplication and addition are commutative, so $F_1$ is invariant under
the swap.

For swapping labels (0,1) F Scores are not symetric.


= Appendix C: Prompt

/*
#text(size: 8pt)[
  #raw(read("../analysis/prep_hpc_coding/prompt-populism.md"), lang: "markdown", block: true)
]
*/

#pagebreak()

= Appendix B: Code
// REQUIRED: Must contain code used to process datasets for examination

/*
== Annotating on Cluster 
#text(size: 8pt)[
  #raw(read("../analysis/prep_hpc_coding/annotate.py"), lang: "python", block: true)
]
== Prompt Validation
#text(size: 8pt)[
  #raw(read("../analysis/01_validate.R"), lang: "R", block: true)
]
== Create Network 
#text(size: 8pt)[
  #raw(read("../analysis/10_create_network.R"), lang: "R", block: true)
]
== Add Network Variables 
#text(size: 8pt)[
  #raw(read("../analysis/20_add_network_variables_largest_component.R"), lang: "R", block: true)
]
== Create Descriptive Statistics and Diagrams
#text(size: 8pt)[
  #raw(read("../analysis/30_descriptives.R"), lang: "R", block: true)
]
== Plot Egonets
#text(size: 8pt)[
  #raw(read("../analysis/40_plot_egonets.R"), lang: "R", block: true)
]
== Models for Hypothesis 1
#text(size: 8pt)[
  #raw(read("../analysis/50_H1_summarized_egonets_regression.R"), lang: "R", block: true)
]
*/

#pagebreak()

// ===== BIBLIOGRAPHY =====
#bibliography(
 "bibliography.bib",
 style: "american-sociological-association"
)
