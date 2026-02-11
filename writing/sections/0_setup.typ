
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
