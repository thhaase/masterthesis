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



















// ====================================================================================================
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
//#lorem(280)
- https://publications.jrc.ec.europa.eu/repository/handle/JRC144603
  - decentralization of information is already happening
== Research Question                [280w,0.5p]
//#lorem(280)

== Summary of other Sections (Basically summary of Introduction Paragraphs)                         [550w - 1 page]
//#lorem(550)

#v(1cm)

REFORMULATE AFTER WRITING RESULTS PART

Question:
How does the usage of populist rhetoric by german Members of Parliament on Twitter affect the politicians engagement communities?

H1: German MPs who use populist rhetoric have more strongly interconnected alters in their reply ego networks than those who do not.
  - linguistic construction of in/outgroup 
  - hyping the ingroup --> selfselection effect keeps only engaged users with knowledge of groups social facts that actively reply to each other @oswald2025






















// ====================================================================================================
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


- populism 
- twitter engagement egonets

== Introduction                        [100w, 0.2page]
//#lorem(100)

== Theoretical Background (start broad) [650w, 1.2 pages]
//#lorem(650)

== Relevant Theory (less broad)         [680w, 1.3 pages]
//#lorem(680)

== Case Study (detailed)                [670w, 1.3 pages]
//#lorem(670)

== Hypothesis (narrow down)             [500w, 1page]
//#lorem(500)

== Summary                             [100w, 0.2 page]
//#lorem(100)




















// ====================================================================================================
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


// Data & Methods                                       [1600w, 3p]  +1058

// Introduction                                        [100w, 0.2p]  +27
// Dataset Sampling & Description                       [264w, 0.5p] +40
// Operationalization & Measure                         [500w. 1p]   +142
// Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p] +20
// Networkanalysis (Threads, Replynetwork, ego networks) [295w, 0.6p] +38
//                                                                   +762	
// Summary                                             [100w, 0.2 p] +33


== Introduction                                        [100w, 0.2p]
//#lorem(100) +27words
This section describes the data, measures, and analytical strategy used to examine how populist rhetoric by German MPs shapes their engagement communities on Twitter. 
After introducing the dataset and collection procedure the 3 step analysis is described. 
First, as the main part of a text analysis populism is operationalized as a three-dimensional construct of People Attitude, Elitist Attitude, and Antagonism, scored by a large language model through a structured annotation prompt.  
Second, the construction of reply threads, the user-level reply network and the exploration of their structure are detailed aswell. 
Finally in a synthesis, politician ego networks are combined with the populism scores produced by the text analysis. Linear Regressions with their controls, aswell as a robustness check and further exploration of the ego networks is described.

#figure(
  image("../images/canva/flowchart.png", width: 100%),
  caption: [Diagram describing conducted Analysis]
)<fig:prompt-accuracy>
#long-caption[

]

== Dataset Sampling & Description                       [264w, 0.5p] 
//#lorem(264) +40words

The Dataset used in this study was kindly provided by Armin Pournaki from the Max Planck Institute for Mathematics in the Sciences, Leipzig. #text(fill: red)[did armin use this data somewhere in his own studies?? maybe I can cite something] The dataset holds tweets and replies directed at German members of parliament aswell as their retweets and referenced tweets, collected over a one wekk from February 7 to February 14, 2022. Only the MPs tweets and their replies are analysed since the reply network best captures social interactions of engagementcommunities. Data were obtained via Twitter's streaming API using two parallel strategies. The follow stream tracked replies to MP-generated tweets, while the track stream captured tweets mentioning MP handles (e.g., #quote[\@username]), including direct and nested replies. Protected accounts were excluded. Both datasets were combined and deduplicated. From the raw data, reply-threads were constructed by linking tweets through directed reply chains. These interactions were then aggregated to a user-level reply network, weighted by the number of exchanges. Thus, the dataset enables an analysis of interaction patterns between politicians and their engagement communities on social media.
To deliniate the set of politicians and add their name and party information, a list of parliamentary members of the 19th, 20th, and 21st German Bundestag is obtained from the Bundestags Webarchiv and added to the original dataset through their twitter-account links @bundestag2026. The complete dataset consists of 693 015 Tweets in the twitwi format @medialab2026.

German political news from 7–14 February 2022 were dominated by the Omikron wave's peak and the escalating Russia-Ukraine crisis. As Russia massed troops for what would become Europe's largest military offensive since WWII, Chancellor Scholz met President Biden to discuss Germany's Nord Stream 2 dependency. Domestically, Scholz's coalition split over a general vaccine mandate, with FDP Justice Minister Buschmann deeming it constitutionally dubious and proposing mandatory physician consultations for unvaccinated adults as a softer alternative.


== Operationalization & Measure                         [500w. 1p]
//#lorem(500) +143words
Current studies almost uniformly base their understanding of populism on #cite(<mudde2004>,form: "prose")'s definition of populism as #quote[two homogeneous and antagonistic groups, ‘the pure people’ versus ‘the corrupt elite’, and which argues that politics should be an expression of the volonté générale (general will) of the people.] @mudde2004[p.543]. While all operationalizations include a #quote[pro-people] and #quote[anti-elite] one of multiple third dimensions is often implemented aswell like the inclusion of anti-pluralist attitudes, the distinction between leftwing and rightwing populism or agitating against horizontal outgroups like minorities @aalberg2017 @castanhosilva2020 @meyer2025. Populist Attitudes are not only measured through surveys @castanhosilva2020, but also through observational studies of political discourse on social media @meyer2025 leveraging LLMs.  

This study operationalizes the core dimensions of #cite(<mudde2004>, form: "prose")'s definition, People Attitude, Elitist Attitude, and Antagonism, by instructing a large language model through an annotation prompt (see #link(<sec:app-prompt>)[Appendix]). Each dimension is defined with explicit scoring anchors: People Attitude and Elitist Attitude are measured on bidirectional scales from --3 to +3, where positive values indicate support for and negative values indicate opposition to the respective group, while Antagonism is measured on a unidirectional scale from 0 (no divide) to 6 (existential threat), with labeled thresholds distinguishing dissatisfaction (1--2), active blame (3--4), and existential threat framing (5--6). The prompt leverages chain-of-thought style reasoning and few-shot examples to guide the models annotation behaviour. To guide the models reasoning letting it question itself throughout the process lead improved the results immensly compared to hard rule-based checks.

The prompt follows the structure described by #cite(<liu2026>, form: "prose"). It begins with a role definition and a pre-analysis check if the text carries any content other than just a link or a user mention. It proceeds by defining #quote[People Attitude], #quote[Elite Attitude] and #quote[Antagonism]. The definition of "the people" is restricted to a broad ordinary majority and explicitly excludes named individuals, lists of specific persons, and narrow subgroups unless the text frames them as standing in for the general public. Similarly, elite criticism is only scored when the target is a generalized powerful class rather than a single individual or a specific policy disagreement.
In the last major section the prompt invokes the chain-of-thought before assigning scores, the model must produce a holistic redescription of the post's rhetorical strategy, an actor-by-actor analysis that classifies each referenced person or group by scale (individual, institution, or generalized class) and dimension-specific explanations that articulate the reasoning behind each score. 
At each step, the model is asked to consider alternative readings and flag its confidence as LOW when a reasonable coder could disagree. 
Three few-shot examples are included to calibrate the model's decision boundaries: a strongly populist post with high people, elite, and antagonism scores, a non-political post that should receive all zeros, and an ambiguous post where institutional criticism could plausibly be read as either targeted policy dissatisfaction or broader anti-elite attitude. This example structure is designed to discourage binary classification tendencies and encourage the model to use the full range of each scale.

The prompt is included as a systemprompt and appended with the to be annotated tweet. The model outputs its reasoning and scores in a json format.


After coding the scores are combined. The three dimension scores are denoted $P in [-3, +3]$ (People Attitude), $E in [-3, +3]$ (Elitist Attitude), and $A in [0, 6]$ (Antagonism). The tweet-level populism score is

$ "Populism" = cases(
  (P - E) times A & "if" A >= 1,
  P - E & "if" A = 0
) $
The subtraction captures the joint rhetorical direction that is positive when the people are elevated and elites denigrated yielding a theoretical range of $[-36, +36]$. 
Combination on the user level is achieved by averaging each dimension separately before recombining. Let $macron(p)_u$, $macron(e)_u$, and $macron(a)_u$ denote the per-user means. The user-level score is

$ "Populism"_u = cases(
  (macron(p)_u - macron(e)_u) times macron(a)_u & "if" macron(p)_u > 0 comma macron(e)_u < 0 comma macron(a)_u > 0,
  macron(p)_u - macron(e)_u & "if" macron(p)_u > 0 comma macron(e)_u < 0 comma macron(a)_u = 0,
  0 & "otherwise"
) $

The gate zeros out users whose average rhetoric is not simultaneously people-affirming and elite-critical, operationalizing #cite(<mudde2004>,form: "prose")'s tripart definition at the actor level. Aggregating dimensions before recombining allows a user to distribute their anti-elite and pro-people attitudes across different tweets.


== Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p]
//#lorem(332) +20words
Computationally methods driven text analysis is based on linguistic concepts. A corpus of documents is divided in tokens as semantically meaningful units of analysis which are often words. The simplest text classification techniques are usually wordfrequency based dictionary methods. Some of which already mechanistically take context of wordappearence into account @ribeiro2016. While simple machine learning classifiers like naive bayes models are statistically more elaborate, deeplearning models are able to integrate interactions between tokens allowing for even better predictions. But deep learning architectures like convolutional neural networks trade variance for increased local bias through usage of filters @sohil2022. Transformer architectures implement modeling of long-range dependencies by implementing self attention on a micro level weighing the importance of every individual input token for other each individual input token @cordonnier2020. Qwen3-235B-A22B-Instruct-2507-FP8 is using more elaborate attention mechanisms like grouped query attention @yang2025.
The model also implements expert segmentation, is multilingual and has 8-bit floating weights @yang2025.

Output quality of large language models is highly dependent on prompt design @liu2026. Prompt engineering is conducted iteratively by drawing small random samples of tweets from the corpus and classifying it using an initial prompt. The resulting reasoning steps contained in the LLMs JSON output are then qualitatively assessed with regard to coherence and later label accuracy. Based on identified shortcomings, the prompt is systematically adjusted and the process is repeated. 
Early versions of the prompt contained were structured in the style described by #cite(<liu2026>, form:"prose"), later additional rule based checks were integrated, the coherence of the phrasing was adjusted and lastly the rulebased checks were changed to questions prompting the LLM to question its judgements and certainty.
External validity is tested after improving the prompt qualitatively until reaching satisfying reasoning performance. 
The expert annotated training dataset of Bundestag for fine tuning the PopBERT populism classification transformer model is used @erhard2025. The dataset contains 8795 sentences of Bundestag speeches with binary annotations of five experts on the people-centrism and anti-elite dimension @erhard2025. After annotating validation dataset with the developed systemprompt and Qwen3-235B-A22B-Instruct-2507-FP8 accuracy 
$ "Accuracy" = frac(1, n) sum_(i=1)^(n) bb(1)["rater"_A^((i)) = "rater"_B^((i))], $
aswell as F scores 
$ "Precision" = frac("both rated positive", "both rated positive" + "only predicted positive") $

$ "Recall" = frac("both rated positive", "both rated positive" + "only reference positive") $

$ F_1 = frac(2 dot "Precision" dot "Recall", "Precision" + "Recall") $
for pairs of expert raters with each other and the LLM annotations are calculated. For validation the bidirectional rating scale of the LLM is collapsed to binary labels matching the direction of pro-people and anti-elite. While the F1 score is not symetric for swapping labels it is symetric for swapping raters (see #link(<sec:app-symetry-of-f1-score>)[Appendix]).




== Networkanalysis (Threads, Replynetwork, ego networks) [295w, 0.6p]	
//#lorem(295) +38words
The reply threads are constructed by treating tweets as nodes that are linked through directed replies. A component in the constructed thread network is then a replythread with one rootnode that is only recieving links marking the direction of a reply. Some reply chains trace back to MP tweets posted before the collection period, so the root node has no row in the dataset. Matching the target tweets user information against the politician table recovers their authorship, recovering 2,631 of 89,561 threads (2.9%). Threads root tweet information like politician with e.g. party and followerinformation, are then stored within the reply tweets of the respective thread and aswell added to each tweet in the reply network. 

The main research question requires a network of interactions plausibly representing an engagement community. A weighted user centric reply network with users as nodes and replies as directed links is constructed. The original tweet-based dataset holding politician and threadinformation served as the basis for construction with its `user_id` and `to_userid` variables. The resulting network is directed with edgeweights based on replycount. It holds 81 295 user-nodes connected through 239 502 reply-links distributed among 1865 components. A giant component holds (77 194) 94% of all nodes. 1207 users are contained in components of size 2, one original user, one replying user, as the threadsize holding the second most nodes. The second largest component held 41 (0.05%) users (see the #link(<sec:app-component-table>)[table] in appendix).
The network analysis is based on the giant component to make computation more feasable leading to a loss of the network periphery without any actual structurally relevant threads.

Tweet-level populism dimensions (people scores, elitism scores, antagonism scores) are aggregated per user by computing weighted means across each user's tweets, then combined into a userlevel composite populism score. These user-level scores are added as vertex attributes to the reply network.

To definitly deliniate the dataset to replies from politicians tweets reply-edges not appearing underneath politicians threads are deleted and isolates are removed. Thereby removing rest-replythreads of e.g. referenced tweets.


== OOPS I FORGOT THE SECTION WITH MY MODELS WHEN STRUCTURING MY PARAGRAPHS/WORDS + 510w
//+762words
A descriptive exploratory analysis describes first the results of the textanalysis and second the networkstructure. 
#text(fill: red)[its all graphbased, except the partyplot and the tweettopics plot]
The textanalysis is conducted with tweets contained in the largest component of the retweet network, that also serves as the basis for the network analysis. Exceptions are the comparison of populism by parties and a wordcorrelation network to infer the tweets content, which are based on the entire tweetdataset including retweets and referenced tweets in order to capture the broader political discourse during the week.

Following that the reply network structure is explored through a visualization using the Distributed Recursive Graph Layout and validated through closer inspection of degree and local clustering distributions @martin2007. 
The Distributed Recursive Graph Layout (DrL) lays out a graph by applying repulsion and attraction forces between nodes to prevent overlap and keeping connected nodes close. Beginning with randomness so nodes can move freely and avoid poor configurations, gradually reducing movement until positions stabilize. Once positioned, spatially close nodes are merged into representative summary nodes producing a coarser version of the graph. The cycle of coarsening and repositioning repeats until the graph is sufficiently small to lay out directly. Finally the process is reversed, expanding each simplified graph back one level at a time, using the prior layout as an initial arrangement.


The structure of politicians ego networks is compared to answer the main question about local engagement communities. Mean alter degree is used as the primary measure of alter interconnectedness, capturing the average number of connections each alter maintains to other alters within the ego network. While density would be a more established measure in usual cases it is inversely related to network size, making comparisons across ego networks of different scales unreliable. As a robustness check, the fragmentation ratio is additionally tested since this measure relates the number of connected components to the overall network, providing a complementary perspective on whether alters form a cohesive neighborhood or fragment into isolated clusters.

For controlvariables the politicians (ego) degree and followercount control for the popularity of a politician while mean thread size of the politicians seeded threads controls for the depth of conversational engagement elicited by that politician. Ego degree captures structural prominence in the reply network, followercount proxies platform-level visibility, and mean thread size accounts for the possibility that longer threads mechanically increase the chance of alter-alter interaction simply by providing more opportunities for reply.

Two OLS regression models are estimated. The baseline model regresses mean alter degree on a binary populism indicator derived from the composite populism score. The full model adds ego degree, follower count, and mean thread size as controls. Comparing the populism coefficient across both models reveals how much of the observed relationship between populist rhetoric and alter interconnectedness is attributable to confounding structural and visibility differences between politicians.

As a robustness check, the fragmentation ratio
$ "Fragmentation" = frac("component count", n_"alters") $
is tested as an alternative dependent variable using the same specification as the full model. Where mean alter degree captures the intensity of alter interconnectedness, fragmentation captures its inverse: the degree to which the ego network consists of isolated clusters. A consistent result across both measures strengthens the claim that populist rhetoric is associated with more cohesive engagement communities instead of an artifact of the chosen operationalization.

To further shed light on which social mechanisms explain a difference in alter interconnectedness, observed edge statistics are compared with a random baseline within each politician's ego network. 
For every ego network, three alter-level attributes are considered: follower count, tweet count, and the composite populism score. Follower count and tweet count proxy platform visibility and activity level, testing whether tie formation is driven by status homophily or preferential attachment among high-activity users. The composite populism score tests the substantively central mechanism: whether alters under populist politicians connect along ideological lines, forming ties with others who express similar levels of populist rhetoric.

Two ERGM-inspired statistics are computed for each attribute. 
\ The absolute-difference statistic captures homophily. For every connected alter pair the mean absolute attribute difference $overline(|x_i - x_j|)_"obs"$ and for every possible alter pair $overline(|x_i - x_j|)_"rand"$ are calculated. A negative relative deviation signals that connected alters are more similar than chance would predict. 
\ The sum statistic captures preferential activity. The mean attribute sum across connected pairs $overline(x_i + x_j)_"obs"$ is compared to the mean across all possible pairs $overline(x_i + x_j)_"rand"$, with positive deviation indicating that edges disproportionately link high-attribute alters. 
\ Both statistics are expressed as relative deviations from the random baseline $(o - r) slash r$ and summarized by median and mean across populist and non-populist ego networks to identify possible systematic group-level patterns in tie formation.

== Summary                                             [100w, 0.2 p]
//#lorem(100) +33
This section described the data, measures, and analytical strategy used to examine how populist rhetoric by German MPs shapes their engagement communities on Twitter. 
The dataset comprises 693,015 tweets collected via Twitter's streaming API from 7-14 February 2022. 
Populism is operationalized as People Attitude, Elitist Attitude, and Antagonism, scored by Qwen3-235B using a chain-of-thought annotation prompt validated against the PopBERT expert corpus. 
Reply threads are reconstructed into a weighted user-level network whose giant component (77,194 nodes, 239,502 edges) serves as the analytical base. 
Two OLS models regress mean alter degree on a binary populism indicator with controls for ego degree, follower count, and mean thread size. As a second dependent variable the ego networks fragmentation ratio provides a robustness check. Further exploration of alter-alter connection compares userbehaviour of populist and non-populist ego networks  



















// ====================================================================================================
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
// Network: ego networks	             [457w, 0.9p]	
// H1: Model/Means	                 [767w, 1.5p]
// HX: Deepdive??	                   [531w, 1.0p]	
// Summary                          [100w, 0.2 p]



== Introduction                     [100w, 0.2p]
//#lorem(100)

== Textanalysis: Result              [510w, 1p]

=== Prompt Validation


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
- put everything in one plot (they can be smaller, direction matters)

- Skewed dataset inflates accuracy
- F scores are not biased through large number of 0 populism scores
- F scores show that prompt is rating tweet on an expert level



#figure(
  image("../images/populism_dimensions_person_level.png", width: 100%),
  caption: [Distribution of populism dimensions per user in the giant component;]
)<fig:populism-dimensions>
#long-caption[
  People score ($macron(p)_u$) and elite score
  ($macron(e)_u$) are binned into 0.25-wide intervals.
  Color visualizes mean antagonism ($macron(a)_u$) per bin;
  opacity describes user count ($n = 29 thin 672$).
]

- something something

#figure(
  image("../images/populism_3d_final.png", width: 100%),
  caption: [Distribution of populism dimensions per user in the giant component;]
)<fig:populism-dimensions-3d>
#long-caption[
  People score ($macron(p)_u$) and elite score
  ($macron(e)_u$) are binned into 0.25-wide intervals.
  Color visualizes mean antagonism ($macron(a)_u$) per bin;
  height describes user count ($n = 29 thin 672$).
]

-woah3d

#figure(
  image("../images/populism_dimensions_person_level_politicians_inset.png", width: 100%),
  caption: [Distribution of populism dimensions per user in the giant component with marked politicians position;],
)<fig:populism-dimensions-politicians>
#long-caption[
  People score ($macron(p)_u$) and elite score
  ($macron(e)_u$) are binned into 0.25-wide intervals.
  Color visualizes mean antagonism ($macron(a)_u$) per bin;
  opacity describes user count ($n = 29 thin 672$).
]

- something something politicians
- #text(fill: red)[IN APPENDIX, yellow font]

#figure(
  image("../images/populism_stacked_dimensions_all_tweets_combined.png", width: 100%),
  caption: [Populism score and its components split by parties and sorted by mean party populism scores.],
)<fig:populism-dimensions-parties>
#long-caption[
  Each bar is one politician; the x-axis shows the share of their tweets at each score level assigned by Qwen3-235B-A22B-Instruct-2507-FP8 with the expert level annotation prompt. The composite populism score equals $("People Score" + "Elitism Score") times "Antagonism Score"$ when $"Antagonism Score" > 0$, otherwise $"People Score" + "Elite Score"$. Dimensions visualized for direction which is increasing the populism score. Parties sorted by descending mean populism score; politicians sorted within party by non-zero share.
]

- widen populism column
- something something party


#figure(
  image("../images/tfidf_wordcorrelations.png", width: 110%),
  caption: [Distribution of populism dimensions per user in the giant component;]
)<fig:populism-dimensions-3d>
#long-caption[
  People score ($macron(p)_u$) and elite score
  ($macron(e)_u$) are binned into 0.25-wide intervals.
  Color visualizes mean antagonism ($macron(a)_u$) per bin;
  height describes user count ($n = 29 thin 672$).
]
- wordcontent tfidf network
- only include if it fits the story somewhere... 

- make 3/4 separate networks with words related to anti elitism, peo people, antag and populism dimension MAYBE

TODO
- introduction first, only hypothesize about main question
- independent from results/conclusion

//#lorem(510)
== Network Analysis

== Network: Descriptives & Structure [469w, 0.9p]
//#lorem(469)

== Network: Hierarchy Deepdive	     [386w, 0.7p]
//#lorem(386)

== Network: ego networks	             [457w, 0.9p]	
//#lorem(457)

== H1: Model/Means	                 [767w, 1.5p]
//#lorem(767)

== Alter-Alter Mechanisms	                   [531w, 1.0p]	
//#lorem(531)

#figure(
  image("../images/6-quasi_ergm_absdiff.png", width: 100%),
  caption: [absdiff (Alter Similarity)],
)<fig:label>

- What is shown
  - For each ego network, the mean absolute difference on a given attribute is computed once over all observed alter–alter ties and once over all possible alter–alter dyads. The ratio (observed − random) / random yields one value per ego network. The circle shows the median across all ego networks in each group, the triangle shows the mean.
- Alter Follower Count
  - Medians are slightly positive for both groups (~35% non-populist, ~25% populist). 
  - Connected alters tend to be more different in follower count than random pairs — mild heterophily. 
  - The non-populist mean explodes to ~330% while the median stays low, indicating a heavily right-skewed distribution driven by a handful of ego networks where very high- and very low-follower alters disproportionately connect. The populist distribution is far more compact (mean ≈ median).
- Alter Populism Score
  - The strongest signal. Both medians sit near −90%, meaning connected alters hold nearly identical populism scores compared to what random pairing would produce. 
  - This is strong, consistent populism homophily across both network types. 
  - The non-populist mean is pulled upward to roughly −15%, again indicating right skew from a few outlier ego networks; the populist mean and median nearly overlap, suggesting a tight, well-behaved distribution.
- Alter Tweet Count
  - Medians hover near zero for non-populists (~−10%) and slightly positive for populists (~+30%). 
  - There is no strong homophily or heterophily on tweet volume for non-populist ego networks, while populist ego networks show a mild tendency for connected alters to differ in tweet activity. Mean and median are close in both groups, so the distributions are relatively symmetric.

#figure(
  image("../images/6-quasi_ergm_nodecov.png", width: 100%),
  caption: [nodecov (Alter Activity)],
)<fig:label>

- What is shown
  - Instead of the absolute difference, the sum of both alters' attribute values is computed per tie and per possible dyad. Positive deviation means ties preferentially form among alters with higher attribute values.
- Alter Follower Count
  - Both medians are positive (~45% non-populist, ~35% populist). 
  - Alters with more followers connect to each other at higher-than-expected rates — a preferential attachment or popularity effect. The non-populist mean is again far above the median (~315%), confirming the same small set of outlier ego networks seen in the absdiff plot.
- Alter Populism Score
  - Both medians are strongly negative (~−80% to −90%), meaning ties form among alters with lower combined populism scores. 
  - The more populist an alter pair is, the less likely they are to be connected. This mirrors the absdiff finding: connections cluster among ideologically similar, low-populism alters.
- Alter Tweet Count
  - Both groups are positive (medians ~35% non-populist, ~50% populist). High-volume tweeters connect more than expected. 
  - The effect is somewhat stronger in populist ego networks. Mean and median are close in both groups, indicating stable distributions without extreme outliers.

- Summary
  - structure is the same across populist and non-populist ego networks!
    - strong populism homophily
    - mild follower heterophily
    - preferential connectivity among active and popular users
  - degree difference
    - populist ego networks show slightly more tweet-driven heterophily and activity effects 
    but the qualitative signatures are remarkably similar. The recurring mean–median divergence in the follower facet for non-populist networks traces to a small number of high-visibility ego networks.

== Summary                          [100w, 0.2 p]
//#lorem(100)



















// ====================================================================================================
// = Discussion
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
//#lorem(100)

== Summary of Results	                                  [347w, 0.7p]
//#lorem(347)

== Interpretation (Relate Results to Literature Review)	[387w,	0.7p]
//#lorem(387)

== Implications (e.g. Significance of Findings, What side is supported, Gap filled)	[372w, 0.7p]
//#lorem(372)

== Limitations & Future Work	                          [394w, 0.8p]
//#lorem(394)

== Summary                                             [100w, 0.2 p]
//#lorem(100)




















// ====================================================================================================
= Conclusion
// REQUIREMENTS:
// - Inverse of introduction: 
//    - starts narrow (answering the final question)
//    - broadens to larger social or scientific relevance
// - Should contain a discussion of broader meaning and significance of findings

// Conclusion [538w, 1.0p]	
//#lorem(538)

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
the swap. #sym.square.filled

For swapping labels (0,1) F Scores are not symetric.

== Component Tables
<sec:app-component-table>
#figure(
  block(width: 70%,
    include "../tables/component_table.typ"
  ),
  caption: [Component size distribution of the reply network]
)<fig:prompt-accuracy>
#long-caption[
   linking users through directed and weighted reply links. A giant component holds most user nodes and the size appearing the most is two.
]
= Appendix C: Prompt
<sec:app-prompt>
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
