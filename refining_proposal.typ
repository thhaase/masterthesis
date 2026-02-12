#set document(title: "Do Scientific Groups Form their own Language in Social Science", author: "Thomas Haase")
#set page(numbering: "1")
#set text(font: "New Computer Modern", size: 11pt)

#align(center)[
  #text(size: 17pt, weight: "bold")[Refining Proposal]
]

#v(2em)

#outline(depth: 2)

#pagebreak()

= Research question

== Problem and Rationale

The search for emergence-supporting properties in scientific fields has a long tradition. A longstanding debate surrounds the issue which type of unit is the optimal way to operationalize groups in science. The scientific discourse discusses the use of communities, thought groups or disciplines @becher1989 @fleck1980 @kuhn1994. How science is structuring itself is also discussed with empirical and statistical methods, mainly using Metadata like authors, years and abstracts of publications @andersen2023 @holtz2017 @leydesdorff2009 @lietz2020. The empirical driven research still does not fully grasp the emergence of scientific fields @lietz2016. Especially understanding the role of homogenization and differentiation in group-formation is an unresolved issue @llanos2019 @volle2024.

Volle et al. @volle2024 investigated the evolution of scientific groups in German and American sociology via block modeling on scopus-data. They found "despite clear paths [of homogenization], we see patterns of differentiation in the development of both fields." @volle2024[p. 235] used thorough measures of academic fields, through different 3 combined networks. The role of language and academic writing style in group formation is still rarely researched to this day @holtz2017. While theory proposes a connection between the use of exoteric/esoteric language and groupformation @wray2007, experiments could show that the theorized development of exoteric language for communication for transparency reasons can not be supported @atkinson2019. The theorized relationship of esoteric language and groupformation is therefore also interesting when taking a linguist point of view.

== Central Question

Because of this the following central question arises:

#align(center)[
  _How is scientific groupformation linked to the development of esoteric communication?_
]

While esoteric communication happens in the context of the ingroup, exoteric communication is conducted with strangers which are considered part of the outgroup @wray2007.

== Specifying Question

Wray and Grace @wray2007 view esoteric and exoteric language use as poles of the same scale which is linked to the degree of compositionality of phrases. The higher the compositionality, the more meaning of an expression is determined by the parts of the expression. When communicating with outgroup members the meaning should therefore be included in the parts of the expression to produce the highest amount of transparency.

*RQ:* Do more stable groups develop stronger esoteric communication?

= Description of Case

Sociological Publications are chosen as a case of interest, because (1) the comparison between different scientific fields would include many difficulties which can not be taken care of in this study. (2) Sociology is a highly diverse and interdisciplinary field where on the one hand, theorists publish texts which are closely related to philosophy and on the other hand, quantitative researchers publish technical reports of statistical findings. (3) At last sociology is chosen, because of the already done research on group emergence and evolution in sociology @volle2024.

= Data sources

To restrict the analyzed articles to the field of sociology the SSCI Journal Category from Web of Science will be used. All articles published in journals which are marked with the SSCI category "Sociology" will be considered being sociological articles. The article metadata will be downloaded via the scopus-api with the "rscopus" library. For the analysis the following metadata are crucial: journal/source, scopus author ID, year, abstracts. The query to download the data will be similar to the following

```
SRCTITLE ( "journal of computational social science" ) AND PUBYEAR
> 2011 AND PUBYEAR < 2024 AND ( LIMIT-TO ( LANGUAGE , "English" ) )
```

Only english articles will be used to ensure proper functionality of the used methods to analyze the downloaded abstracts.

= Measures

== Scientific Groups

Like in Volle et al. @volle2024 2 networks will be created to give insights into the evolution/development of scientific groups. Like Volle et al. @volle2024 a author-coauthor network will be created using the Scopus Author IDs to represent the social collaboration/thought collective aspects of scientific-group-formation. To measure influence of discursive practices the tf-idf weighted word frequencies will be used to create an author-co-word network where authors with similar foci are connected. The described two networks will be combined to create a multirelational network.

Networks are created for 4 arbitrarily chosen windows of time. For each time slice a blockmodeling will be used to aggregate the networks into analyzable units. The different blockmodels will be connected via calculating the similarities between the different blocks @volle2024. Blocks with a high similarity in all 4 time slice can be viewed as paradigmatic @volle2024. The Language-measures are created for every article and summarized for each block using means and variance for every block.

== Compositionality

To generate a score which indicates the level of esoteric language for each group in each time slices (1) the compounds in the literature have to be detected and (2) the compositionality of the compounds will be calculated. The "level of own language" is indicated by $1 / "compositionality value"$, because the more meaning of a phrase is determined by it is parts the more exoteric the language will be.

To detect compounds the POS-Tagger implemented in the spacy python library will be used @honnibal2015.

Initially, word embeddings are created from corpora of the texts authored by researchers of the ingroup and outgroup of a certain time slice. The embeddings represent the semantic meaning of words in a vector space. For each earlier detected compound, a compositionality score is calculated via the cosine similarity between the compound's vector representation and the mean vector of its constituent parts. This metric is used as a proxy for the degree of semantic transparency of the compound, leveraging the principle that vector similarity in the embedding space correlates with semantic similarity.

= Analysis

The described "Level of own language" is interesting to analyze on its own. A similar block-evolution plot like in Volle et al. @volle2024 is created and the corresponding "level of own language" scores is added to the blocks/groups. This way the connection of group evolution and language formation can be interpreted together.

To gain more insights the "level of own language" of the ingroup is compared with the average "level of own language" of all other groups of the time slice. The resulting difference can be used to create an order of strength of the own language of one group compared to the other groups.

#pagebreak()
#bibliography(
  "./writing/My Library.bib", 
  title: "References", 
  style: "american-sociological-association"
)
