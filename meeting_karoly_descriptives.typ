#import "@preview/cmarker:0.1.1": render

#set page(margin: 2.5cm, paper: "a4")
#set text(font: "Linux Libertine", size: 11pt)
#set par(leading: 0.65em)

// ── Header ───────────────────────────────────────────────────────────────────
#align(center)[
  #text(size: 18pt, weight: "bold")[Meeting - Feb 19, 2026]
  #v(4pt)
  #text(size: 10pt, fill: gray)[February 17, 2026 · Thomas Haase]
]
#line(length: 100%, stroke: 0.5pt + gray)
#v(6pt)
= Summary
- Data: (User)--reply-->(User) network created from reply-trees below politicians tweets. 
- Power-law structure indicates hierarchical network
- One giant component with ~96\% of all nodes
  - giant component is sparse and hub-driven (low clustering, mediocre reciprocity).
- More users send replies than receive them (outdegree > indegree), and receiving replies is far more concentrated

#line(length: 100%, stroke: 0.5pt + gray)

// ── Intro 
== Data Collection Process
(Data Scraped by Armin Pournaki):\

Data were collected via Twitter's streaming API using two parallel strategies to capture reply interactions involving German MPs. The follow stream tracked replies to MP-generated tweets. The track stream captured tweets mentioning MP handles (e.g., "\@username"), including direct replies and nested replies to reconstruct complete conversation threads. Protected accounts were excluded. Both datasets were combined and deduplicated to create the final reply dataset.

#v(12pt)

= Discussion Trees (Tweet ---reply--> Tweet)
#align(center)[#image("./images/1-gt-degree-frequency.png", width: 90%)]
- Powerlaw
  - many tweets without/ with few replies
  - few tweets with a lot of replies

#align(center)[#image("./images/1-gt-componentsize-frequency.png", width: 90%)]
- Powerlaw
  - many discussionthreads with small size
  - few discussionthreads with a lot of replies

= User-centered Network (User ---reply--> User)

#align(center)[#image("./images/1-gu-degree-frequency.png", width: 90%)]
#align(center)[#image("./images/1-gu-componentsize-frequency.png", width: 90%)]
- There is one Giant Component
The giant component holds 95\% of all nodes in the network
#include "tables/component_table.typ"

= Largest Component
#include "tables/network_structure_descriptives.typ"
- tiny density 
  - sparse network
- large degree standard deviation 
  - few super central nodes
- 13\% of connections are mutual 
  - few actual discussions, most interactions between "strangers"
  - People post to politicians root tweets, Politicians do not answer
- slightly disassortative 
  - high-degree hubs connect to low-degree periphery nodes
- low short path rate (4.35)
  - lot of users probably connected through hubs
- little clustering (12\%)
  - few smaller groups
- sampled k-core max 24 
  - pretty well connected core 

#align(center)[#image("./images/3-degree-distribution.png", width: 90%)]

- Outdegree > Indegree 
  - more users send a moderate number of replies than receive them

- Indegree has a longer tail than outdegree 
  - some users receive replies from a lot of different people, but no single user is actively replying to thousands of distinct others. Receiving replies is more concentrated than sending them.

#align(center)[#image("./images/3-centrality-measures.png", width: 100%)]

- Eigenvector
  - very compressed
    - most users are connected to low periphery users
  - few nodes with high centrality
    - suggesting a small, tight, influential core isolated from the rest
