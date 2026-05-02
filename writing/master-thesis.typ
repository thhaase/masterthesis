#import "@preview/cetz:0.3.4"

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
#set heading(numbering: none)
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

// pagecount to 1
#counter(page).update(1)
// Headingcount to 1
#set heading(numbering: "1.")
#counter(heading).update(0)

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

// Introduction                     [1,110w, 2.1 pages, ~10%] -600 words
// Motivation & Relevance Statement [518w, 0.5p]
// Research Question                [42,0.5p]
// Summary of other Sections (Basically summary of Introduction Paragraphs)                         [550w - 1 page]


Social media threatens democracy through several channels, one of them being populism @lorenz-spreen2022. While scholars debate definitions, populist movements are democratizing authoritarian regimes and destabilizing Western democracies @lorenz-spreen2022. This is hardly surprising considering the essence of populism.

Populism research has historically been divided by geographical focus, methods, and host ideologies @hunger2022. Since 2016 the research landscape has been dominated by political science perspectives converging on populism as a discursive practice @tugal2021. They almost uniformly adopt #cite(<mudde2004>, form: "prose")'s definition of populism as #quote[an ideology that considers society to be ultimately separated into two homogeneous and antagonistic groups, 'the pure people' versus 'the corrupt elite', and which argues that politics should be an expression of the volonté générale (general will) of the people] @mudde2004[542].

While theoretical work refines the concept largely within Marxist traditions, relational and systems-sociological perspectives have remained peripheral @tugal2021 @hunger2022. This is puzzling, because Mudde's definition is itself relational: populism is constituted through the antagonism between two groups. Simmel already connected antagonism to group cohesion, noting that groups are #quote[...held together by a shared aversion [...] to which entirely foreign elements are drawn by the commonality of an antagonism.] @simmel1908[Ch.4]. A relational reading of Mudde is therefore not a far fetched but literally a theoretical operationalization of it.
//- write more about populism in general

One of computational social science's original aims is to make use of digital data for social science questions @lazer2009. Since the dynamics of complex systems are baked into the design of social media, researchers should take a complex-systems perspective when studying them @bak-coleman2025. Yet existing large-scale observational social media studies of populism analyze only textual content @erhard2025 @yarchi2021 @serrano2020. Populism has rarely been connected to networks.  

This study fills that gap by asking:

#quote[How does populist rhetoric by German parliamentary members shape the structure of their reply communities on Twitter?]

/*
The theoretical framing draws on social movement research combined with relational and systems-theoretic sociology. Parties are movements competing for political power @tilly1978[117], and they do so in platform environments that maximize attention @simon1971. Twitter is not a neutral arena in which rhetoric is received but a medium whose architecture actively structures who encounters whom. Populist rhetoric, by linguistically constructing a pure people against a corrupt elite, offers a candidate identity formula around which such encounters could stabilize into durable patterns of engagement. From a Luhmannian perspective, the reply network is a self-referential communicative system that reproduces itself through the recursive connection of utterances to prior utterances; what persists is not speakers but the patterns of connection their communications leave behind @luhmann1984. #cite(<white2008>, form: "prose") complements this view from the other direction. Identities emerge based on events like a politician using populist rhetoric @white2008[Ch.1]. While Identities can develope to a point of conciousness a stronger connected engagementcommunity represents the second sense of identity formation @white2008[10]. 
Read together, the two frameworks suggest that populist rhetoric on Twitter is a story-work attempting to constitute a people-ingroup within an ongoing communicative system. Its effects should be legible as a structural signature in the local engagement neighborhoods of the politicians who deploy it rather than only in the content of what is said.
*/
Populism research is divided over whether populism is a thin or a thick ideology. The minimal definition reads it as a vertical antagonism between a homogeneous people and a homogeneous elite @mudde2004, often enriched with a horizontal dimension constructing the people additionally against outside groups @brubaker2017. What unifies all perspectives is the minimal definition as a common denominator and the intuition that populism is system-destabilizing @lorenz-spreen2022. The definitions of populism implicitly are connected to representative democracy. Democracy selects its communications through the Government/Opposition distinction @luhmann1987, and populism is then the reproduction of this distinction at the level of a social movement (Elite/People) attempting to place itself as a valid democratic group. Social media amplifies this code @lorenz-spreen2022 and Twitter in particular is not a neutral arena in which rhetoric is received but a medium whose recommender architecture actively structures who encounters whom @x2026. Parties are then movements competing for political power in this attention environment @tilly1978[117] @simon1971, and populist rhetoric constructs the distinction of the pure people against a corrupt elite. This gives encounters a distinction around which they can stabilize. Engagement in this medium is not agreement @morselli2026 but a structural fact, users repeatedly showing up in the same place around the same politician whatever their reason for doing so, and whether such stabilization actually occurs is then a question about communication and not about speakers.

The methodological approach translates the outlined theoretical ideas by using a twitter reply network to operationalize social interactions on social media. Compared to retweets and mentions replies are a way of directly answering to a message another person published. The dataset contains politicians tweets and their replies to construct such a replynetwork. To explore the effect of a politician using populist rhetoric on their community all tweets are labeled by the amount of populist attitude they communicate. This textanalysis is achieved through a fewshot LLM Qwen3-235B annotation using an expert validated systemprompt. The egonetworks of politicians are extracted and their structure compared by their usage of populist rhetoric to explore if the expected relationship can be observed. 

- Results & Discussion

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


// Literature Review                    [2 740w, 5.2pages, 25%] 2490 ==> -250

// Introduction                        [100w, 0.2page]
// Theoretical Background (start broad) [650w, 1.2 pages]
// Relevant Theory (less broad)         [680w, 1.3 pages]
// Case Study (detailed)                [670w, 1.3 pages]
// Hypothesis (narrow down)             [500w, 1page]
// Summary                             [100w, 0.2 page]




//== Introduction                        [100w, 0.2page]
//#lorem(100)



Populism research is divided over one main question: Is populism a thin or thick ideology? And if it is thick, how so? The following section provides an overview of the conflict and explains the implicit theoretical source of the conflict. The second half proposes a new generalizing perspective on the topic motivated through already observed micro mechanisms. 
== Populist Theories of Populism
//== Horizontal vs. Vertical Populism
2004 Cas Mudde proposed a minimal definition of populism as an ideology where a message is framed in a way that the powerless homogenous people stand against a ruling homogenous elite as antagonistic groups @mudde2004. 
This definition has been considered "thin", because it only considers a vertical divide of society @brubaker2017. Vertical in the sense that one group is ruling the other. When read as an ideology #cite(<mudde2004>, form: "prose") s mininmal populism implicitly includes a class component as the core of its definition @yates2026. The definition is currently the most cited work on populism. This can be explained with the minimalism increasing the potential of connected communication for theorists discussing the work @tugal2021 @urbinati2019 @brubaker2017 @luhmann1987. Empirical studies operationalized the main dimensions of people-centrism and anti-elitism in surveys and finetuned bert classifier PopBert on german Bundestagspeeches @castanhosilva2020 @akkerman2014 @erhard2025.
Often this minimal definition is combined with some other dimension like antipluralism or the distinction between left and rightwing populism @erhard2025 @castanhosilva2020. Theorists combine the thin definition with institutional and substantive analyses when discussing populism but those are chosen rather arbitrary @tugal2021. The minimal definition is part of the same family of subjectivist definitions as discoursive and performative marxist and postmarxist definitions built on #cite(<laclau2005>, form: "prose") #cite(<tugal2021>, form: "normal").  

Combining the minimal definition with more substantial categories of analysis not only thickens the analytic concept but also increases its theoretical richness. #cite(<brubaker2017>, form: "prose") criticised the minimal definition for only capturing his proposed vertical dimension without acknowledging the horizontal distinctions between "the people" and outside groups. For example one thickness-increasing addition would be that left-wing populism defines "the people" economically or politically against threats like globalization and imperialism, while right-wing populism defines them culturally or ethnically against outside groups and "internal outsiders" perceived as not belonging to the nation @brubaker2017. 
The more terms are added and connected the stronger and thicker the assumed ideology gets. #cite(<brubaker2017>, form: "prose") for example researches 5 different elites, more outsidegroups and the heartland. This comes with the caveat that the more the concept of populism is enriched the more it #quote[lumps together] disparate political projects with disparate social bases and modes of action @brubaker2017 @medzihorsky2024. 

#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let dark = rgb("#16161D")  // Eigengrau

    line((-5.4, 0), (5.4, 0),
      mark: (start: ">", end: ">", fill: dark),
      stroke: 1.4pt + dark)
    line((0, 0), (0, 4.1),
      mark: (end: ">", fill: dark),
      stroke: 1.4pt + dark)

    content((1.1, 3.8),
      text(weight: "bold", size: 11pt, fill: dark)[The Elite])

    content((-1, 3.7),
      text(style: "italic", size: 8.5pt, fill: dark)[The Media])
    content((-2.4, 4),
      text(style: "italic", size: 8.5pt, fill: dark)[Politicians])
    content(( 3.2, 4.1),
      text(style: "italic", size: 8.5pt, fill: dark)[Large Companies])



    content((1.3, 0.2),
      text(weight: "bold", size: 11pt, fill: dark)[The People])

    content((-4.7, 0.3),
      text(style: "italic", size: 8.5pt, fill: dark)[Immigrants])
    content(( 4.7, 0.3),
      text(style: "italic", size: 8.5pt, fill: dark)[The poor])

    content((-3.3, 0.7),
      text(style: "italic", size: 8.5pt, fill: dark)[Ethnic groups])
    content((-1.4, 0.2),
      text(style: "italic", size: 8.5pt, fill: dark)[Religious groups])
    content(( 3.2, 0.3),
      text(style: "italic", size: 8.5pt, fill: dark)[LGBTQ+])
    content(( 2, 0.6),
      text(style: "italic", size: 8.5pt, fill: dark)[The unemployed])

    content((6, -1),
      text(size: 8.5pt, fill: dark)[
        horizontal axis \
        thick populism \
        (Brubaker 2017)
      ])
    content((1, 4.5),
      text(size: 8.5pt, fill: dark)[
        vertical axis \
        thin populism \
        (Mudde 2004)
      ])
  }),
  caption: [Vertical and horizontal dimensions of populism]
) <fig:populism-axes>
#long-caption[
  After #cite(<mudde2004>, form: "prose") and #cite(<brubaker2017>, form: "prose"). The vertical axis captures the thin, minimal definition: "the people" constructed against "the elite". The horizontal axis captures Brubaker's thick extension, in which "the people" is additionally constructed against horizontal others. The labels along the axis are illustrative examples of such horizontal others; their position on the axis is not meaningful and the horizontal dimension is not equivalent to a left–right axis.
]

But is populism really such a densely connected set of concepts, aka an ideology? And is it democratic or antidemocratic?
While those putting left and rightwing populism on one axis do not necessarily assume that they are part of the same dimension they use it to enrich populism in order to bring it closer to an ideology. #cite(<yates2026>, form: "prose") argue that on an ideological level there is no right-wing populism. Leftwing and rightwing populists disagree on the meaning of the "people" they invoke. The leftists say #quote[plebs], the rightwing say #quote[ethos] when saying #quote[the people]. While left wing populism aims at increasing marginalized groups visibility, right wing populism extends the privalige of already visible groups and leaves the oppressed and exploited oppressed and exploited @yates2026. For rightwingers populism is then not part of an ideological core but merely a strategy for gaining votes. They abuse populisms ability to unify different cleavages splitting the critique of elites for different reasons @urbinati2019. 
In short, even though thin vertical populism is often enriched with the left and right dimension only leftwing populism can be ideological. The distinction becomes clearer when populists gain power. Populist leaders in power either (1) reaffirm their pro-people identity, remaining in a permanent electoral campaign or (2) change rules to strengthen their decisionmaking power @urbinati2019. While the populists continue to use propaganda facist populists revoke checks and balances @urbinati2019. Populist ideology arrives at a so called #quote[partyless democracy] where the people represent themselves through populist protests and parties openly rule only for their own good @urbinati2019 @kriesi2014 @brubaker2017. 

Luhmanns Systemtheory provides a contrasting image to the relation between populism and a democratic state of the different scholars. For Luhmann democracy is not making all decisions participatory because then one would reduce all decisions to decisions about decisions which Luhmann calls #quote[Teledemobureaucratization] @luhmann1987. This favours opaque powerstructures and insiders, just like the partyless democracy claims. In its essence democracy for Luhmann is the division of the elite into government vs. opposition which becomes the systems binary code to select which communications are considered relevant or not. What is so special about this binary code in particular is that it dissolves fundamental paradoxes that all systems with organized powerdifferences inherit @luhmann1987. This split only works when society is already differentiated in enough horizontal functional systems that it does not need a head of state anymore @luhmann1987. Society then is too big and previously relevant systems have emancipated themselves from their role, sustaining themselves through autopoiesis. Descriptively, this overlaps with the diagnosis of the powerless democracy, even if Luhmann's framework remains value-neutral where Urbinati's is normative. Crucially though, "elite" here is a functional designation, those holding or contesting office, not a moral indictment. Populism's elite/people distinction is something else: it reintroduces a moral coding, pure vs. corrupt, into a political system whose code is government vs. opposition. From a Luhmannian perspective the thin populist ideology therefore does not naturally arise from the code but presses against it, as an attempt to override the functional split with a moral hierarchy.

At this point a distinction between two cases can be made, although both already presuppose a representational vocabulary that Luhmann himself tries to dissolve. Either the representative democracy is seen as a genuine and working representation of the people or it is seen as a functionally differentiated system that emancipated itself from society where parties already only rule in their own favor. In the first case representative democracy is the rule of the people and in the second case representative democracy is the rule of the elite. Read through Luhmann the second framing is closer to the operational reality, and the thin definition is then an accurate representation of the actual structural condition where thickening would be optional.

When scholars choose between a thin or thick definition of populism, they often commit implicitly to a perspective on democracy, even where the choice is presented as merely methodological. A thick definition adds content like ethnic identity, antipluralism, or outside groups, and it treats populism as something that corrupts a working democracy. This only makes full sense if you already believe democracy genuinely represents the people, otherwise there would be nothing for populism to corrupt. A thin definition, with just the elite-people divide, fits much better with the idea that democracy has closed in on itself and mostly serves its own elite. The thin divide then describes a real structural split rather than a distortion. Most researchers overlook this tension, and some hold both sides at once, they define populism thinly but still frame it as a danger to a democracy that genuinely works. 
Read through Luhmann, populism is at once an accurate diagnosis of a political system that emancipates itself from the people it wants to represent and a reactive moralization at the same time that would collapse the government/opposition code by declaring one pole legitimate and the other not. The thin definition is therefore revealing in both directions. It captures the structural condition the powerless-democracy describes and it carries within itself the moral re-entry that makes populism a de-differentiation threat rather than a corrective. In other words, populism describes a real problem in the political system as a differentiated functional system, but its moralizing it at the same time trying to replace the structural code with a moral one.

What in the end unifies all perspectives is the minimal definition as a common denominator and the general intuition that populism is political-system-destabilizing @lorenz-spreen2022. 

== Populism and Social Media

Social media populism studies all implicitly understand populist as a form of communication since they analyse it on a social media plattform connecting all of its users. 

If populism arises from the elite-people code of representative democracy, social media amplifies this code and decouples it from traditional institutions. Digital media use is consistently associated with higher populism, with causal evidence for far-right support and even ethnic hate crimes in democratic and authoritarian regimes @lorenz-spreen2022. The question is not whether social media matters but what it does structurally. The common explanation is affordance. Social media is cheap, viral and engagement-driven, exploited by populists for demagogic, anti-establishment and people-praising messaging including name-and-shame strategies @gildezuniga2020. #cite(<cassell2021>, form: "prose") confirmed this through qualitative coding of populist leaders tweets across Latin America and Europe, where populist frames outperformed pluralist, technocratic and neutral tweets in likes and retweets. Yet this engagement advantage is asymmetric. Dutch populists reciprocate interaction on Twitter less than non-populists @jacobs2019. Populist communication mobilizes attention upward without distributing it downward. Politicians also adapt to platforms rather than to policy. #cite(<stier2018>, form: "prose") used a Bayesian semi-supervised single-membership language model to show that candidates use Facebook and Twitter for distinct purposes, discussing campaign events and platform-specific topics rather than policy. The audience is no longer a mass but chooses its broadcaster, which makes strategic tailoring rational. 
#cite(<hu2024>, form: "prose") explores the engagement of political tweets labeled by topics and finds few follower of politicians using selfexpressive, argumentative aswell as mobilizing language. These patterns aggregate at the group level. #cite(<stier2017>, form: "prose") showed AfD and Pegida share Facebook userbases, mutually like each other and converge on topics like crime, sexual assaults, EU referenda and #quote[state and the people]. #cite(<stier2025>, form: "prose") found through linked survey and webtracking data that radical right populists and their supporters avoid public broadcasters and expose themselves to alternative channels. #quote[How to talk about and select media sources seems to have developed into a core component in the construction of a radical right group identity and a shared information 'safe space' for political information] @stier2025. Group identity is built around the choice of information infrastructure itself. This ties populist communication to a legitimacy crisis rather than to a left-right axis. Analyzing 32 million tweets from parliamentary accounts in 26 countries, #cite(<tornberg2026>, form: "prose") found that neither left-right nor populism alone explains misinformation spread. Both left and right-wing populists consume more misinformation, but only the rightwing believe themselves better informed. The radical right has built an alternative media ecosystem in symbiotic relationship with attention-economic platforms @tornberg2026. Consistent with the Luhmannian reading above, once a functional system emancipates itself from its societal task it begins to produce its own environment to keep itself alive. 

To summarize, populism is a style of communication that constructs the divide between the people and the elite with usually rule-destabilizing consequences. Even though we can not know the individuals motivations or reasons behind usage of populist rhetoric, what is sure is the role politicians assign themselves to and what being a politician implicates. From a point of political communication politicians use this language in order to put themselves into a position to mobilize and govern.


== Language and the Meso Level

Up until now it was established that populist language is used by politicians on social media platforms and that it has been connected to certain language aswell as engagementmetrics.

But engagementmetrics only report on the reactions of single users, but users interact, especially on social media platforms. Those interactions of single users are conceptually not independent since social media recommender algorithms use collaborative filtering. This is especially well known for Twitter since X open sourced the architecture of the platforms recommender algorithm @x2026. Multiple steps in the recommender algorithm are enriched with collaborative filtering techniques like SimClusters, the UTEG (User-Tweet-Entity-Graph) and the knowledgegraph @x2026. Through this algorithm Twitter shapes the interactions on its platform. But not only from a technical perspective groupdynamics between users should be considered. One of the oldest sociological idea is that antagonistic groups shape each other. 
#quote[... that through [the dispute] not only does an existing unit concentrate itself into a more energetic unit, and radically eliminate all elements that could blur the sharpness of its boundaries against the enemy – but that [the dispute] brings together persons and groups who otherwise had nothing to do with each other.] @simmel1908[251]. 

For Simmel a group needs at least three persons @simmel1908[Ch2]. This is mainly because when one person leaves the group it doesnt automatically dissolve like if in the case of only two persons. For three persons the group can sustain itself if a person leaves the group. That a group emerges in the real world two processes are needed, homophily for the group cohesion and repulsion of others for defined group boundaries @stadtfeld2020. Pure attraction only explains a groups expansion while a heterophob repulsion mechanism creates stable groups by defining its boundaries. #cite(<stadtfeld2020>, form: "prose") show this by calibrating a stochastic actor oriented model to 479 students from 13 schoolclasses in order to simulate how friendship and dislike networks emerge.
In Twitter retweet networks language is used as a marker for opinion-based group formation @morselli2026. Opinion based group formation requires opinions as identity markers that individuals use to transition from holding an opinion to selfcategorizing themselves through the opinion @morselli2026. In linguistic theory the identity markers changing meaning for the ingroup is described through the distinction between esoteric and exoteric language @wray2007. Esoteric language is specialized in the sense that it is used for ingroup communication and outsiders can not understand it. Exoteric language is more selfexplanatary and is used for communication with outsiders @wray2007. The coevolution of language and social groups is already activly researched in the science of science. For example #cite(<schmitz2025>, form: "prose") trace the evolution of scientific groups in the US and German sociology through a stochastic blockmodel of a multilayer network operationalized through co-word usage, shared citations and co-authoring. 

The social media studies so far were mostly largescale observational studies. Experimental studies in controlled contexts can give closer insight into the social mechanics of online group/discussion formation. #cite(<oswald2025>, form: "prose") payed participants to engage with each other about political topics in Reddit forums they moderated. Participants additionally filled out surveys regularly over a period of four weeks. When users percieved a discussion to be toxic they did not engage in the discussion. The users who engaged, engaged more when the discussion was polarized and toxic @oswald2025. With a Luhmannian read the results can be generalized to the formation of a code in the discussion as a social system. Users percieve the community as positive/negative according to their own standards and start with the second stage of communication: "Mitteilung" @luhmann1984[Ch.4]. While different persons engage according to their own evaluative codes their communication creates thematic and meaning structures @luhmann1984[Ch.4]. The social-discussion-system starts to reproduce itself. If now the discussions would start to be selfdescriptive the system starts making a distinction between itself and its environment and emerge as a differentiated unit itself @luhmann1984[Ch.4]. #cite(<oswald2025>, form: "prose")s experiment also include the persons being driven away from the discussion through e.g. the evaluation of a toxic environment. With the Luhmannian read, outside of the experimental context they would put their attention somewhere else, creating new opportunities for social systems to emerge, driving again others away. On one hand the discussion becoming more homogenous reduces complexity, but it also increases comprehensible complexity #cite(<luhmann1984>, form: "prose"). Higher connectivity (Netness) around a certain category (Catness) is equivalent to a higher amount of organization of a group @tilly1978[63]. Parties are aggregating members loyal to the category, aka political interest and communicative practice, aka code, making it distinct from its environment @tilly1978[76]. Parties are then social movement because they are mobilizing others @kusche2016a @tilly1978.


#figure(
  cetz.canvas(length: 1cm, {
    import cetz.draw: *

    let dark  = rgb("#16161D")
//    let green = rgb("#506c81")
//    let pink  = rgb("#d14b4b")
//    let beige = rgb("#778efd")
    let green = rgb("#6F9A62")
    let pink  = rgb("#16161D")
    let beige = rgb("#D4BE90")

    let panel-arrow(from, to) = {
      line(from, to, mark: (end: ">", fill: dark), stroke: 1.2pt + dark)
    }

    // --- Panel 1
    //circle((-5, 0), radius: 1.7,
    // stroke: (paint: dark, dash: "dashed", thickness: 0.5pt))

    let p1-dots = (
      (-5.7, 0.6, green), (-4.5, 0.8, pink),
      (-5.1, -0.4, pink), (-4.4, -0.5, green),
      (-5.6, -0.7, green), (-5.3, 0.9, pink),
      (-4.7, 0.0, green), (-5.4, -0.1, pink),
      (-4.3, 0.3, pink),  (-5.9, 0.0, green),
      (-4.6, -0.9, pink), (-5.0, 0.3, green),
    )
    for (x, y, col) in p1-dots {
      circle((x, y), radius: 0.13, fill: col, stroke: none)
    }

      content((-5, -2.25),
//      text(weight: "bold", size: 9.5pt, fill: dark)[t#sub[0]])
  //  content((-5, -2.85),
      text(size: 8pt, fill: dark)[heterogeneous \ communication])

    // arrow 
    panel-arrow((-3.05, 0), (-1.85, 0))

    // --- Panel 2
    circle((0, 0), radius: 1.6,
      stroke: (paint: dark, dash: "dashed", thickness: 0.5pt))

    // green dots
    let p2-green = (
      (-0.3, 0.2), (0.4, 0.5), (-0.5, -0.3),
      (0.2, -0.5), (0.6, -0.1), (0.0, 0.6),
    )
    for pt in p2-green {
      circle(pt, radius: 0.13, fill: green, stroke: none)
    }
    line((-0.3, 0.2), (0.4,  0.5),  stroke: 0.4pt + green)
    line((0.4,  0.5), (0.6, -0.1),  stroke: 0.4pt + green)
    line((-0.5,-0.3), (0.2, -0.5),  stroke: 0.4pt + green)
    line((-0.3, 0.2), (-0.5,-0.3),  stroke: 0.4pt + green)


    let p2-leaving = (
      (-0.80,  1.00, -1.60,  1.55),
      ( 1.00,  0.90,  1.70,  1.45),
      (-0.20, -1.10,  0.25, -1.85),
      (-1.05, -0.50, -1.85, -0.85),
    )
    for (x1, y1, x2, y2) in p2-leaving {
      circle((x1, y1), radius: 0.12, fill: pink, stroke: none)
      line((x1, y1), (x2, y2),
        mark: (end: ">", fill: pink), stroke: 0.7pt + pink)
    }

    content((0, -2.25),
    //  text(weight: "bold", size: 9.5pt, fill: dark)[t#sub[1]])
    //content((0, -2.85),
      text(size: 8pt, fill: dark)[selection by \ evaluative code])

    // arrow
    panel-arrow((1.85, 0), (3.05, 0))

    // --- Panel 3
    circle((5, 0), radius: 1.4,
      stroke: (paint: dark, thickness: 1.4pt),
      fill: green.lighten(82%))

    let p3-dots = (
      (4.5,  0.3), (5.3,  0.5), (4.4, -0.2),
      (5.0, -0.5), (5.4,  0.0), (4.7,  0.0),
      (5.0,  0.7), (5.5, -0.3),
    )
    let p3-edges = (
      (0, 1), (0, 2), (0, 5), (0, 6),
      (1, 4), (1, 5), (1, 6),
      (2, 3), (2, 5),
      (3, 4), (3, 7),
      (4, 5), (4, 7),
      (5, 6), (5, 7),
    )
    for (a, b) in p3-edges {
      line(p3-dots.at(a), p3-dots.at(b), stroke: 0.4pt + green)
    }
    for pt in p3-dots {
      circle(pt, radius: 0.13, fill: green, stroke: none)
    }

    // --- recursion hint
    circle((5.5, 2.0), radius: 0.4,
      stroke: (paint: dark, dash: "dotted", thickness: 0.5pt))
    circle((5.35, 1.90), radius: 0.10, fill: beige, stroke: none)
    circle((5.70, 1.95), radius: 0.10, fill: beige, stroke: none)
    circle((5.50, 2.20), radius: 0.10, fill: pink,  stroke: none)
    content((5.5, 2.65),
      text(style: "italic", size: 7pt, fill: dark)[new system \ forming])

    content((5, -2.25),
    //  text(weight: "bold", size: 9.5pt, fill: dark)[t#sub[2]])
    //content((5, -2.85),
      text(size: 8pt, fill: dark)[differentiated system \ system / environment])

  }),
  caption: [Three-stage account of group emergence in online discussions]
) <fig:groupformation>
#long-caption[
  After #cite(<oswald2025>, form: "prose") read through #cite(<luhmann1984>, form: "prose") and #cite(<tilly1978>, form: "prose"). At the first step communication is heterogeneous: users with divergent evaluative codes (positive in green, negative in pink) all participate in the same discussion. At the second step the system selects: users who evaluate the discussion negatively disengage, while those who evaluate it positively intensify and form initial ties. At the last step a homogenized code reproduces itself, ties densify (Tilly's netness around a shared catness), and the discussion makes a distinction between itself and its environment, emerging as a differentiated social system. The displaced users seed new systems elsewhere, restarting the cycle.
]
Populism (Elite/People) is the reproduction of the democratic system (Government/Opposition) through the social movement as a subsystem of the political system. Democratic system select communication through this code @luhmann1987 and by reproducing it the social movement attempts to plcae itself in a position of being a valid democratic group. This explains why right-wing populists use this distinciton as a mobilizaiton strategy even though it contradicts their elitist ideology @yates2026. Being for the people as an ingroup is very universal since every voter can be part of the constructed ingroup. Communication with this distinction has great potential for "Anschlusskommunikation". It drags everyone in the political arena, puts citizens at the negative-opposition side of the Government/Opposition distinction inviting them to participate in the movement empowering them as political citizens. 
#align(center)[
  #block(width: 90%)[
    A more active engagement community should therefore manifest itself through more observed ties in the area around the populist politician.
  ]
]
Or more precisely for the given Dataset:

#align(center)[
  #block(width: 90%)[
    German MPs who use populist rhetoric have higher interconnected alters in their reply ego networks compared to MPs using less populist rhetoric.
  ]
]

Engagement networks are special in the sense that they do not reflect who agrees with whom but who interacts with whom. #cite(<morselli2026>, form: "prose") found that close individuals in the twitter retweet network can have different opinions. Even though on a linguistic basis at the first glance it seems unreasonable, but we can imagine the extreme case. A user is always coming back to a politicians tweets and its fanbase to share their disagreement. Are they part of the group or not? The person is not part of the fanbase but definitly part of an engagement community where individuals continuously show up in the same place and position, no matter why. 


//== Summary                             [100w, 0.2 page]
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


// Data & Methods                                       [1600w, 3p]  +1058 -100summary

// Introduction                                        [100w, 0.2p]  +27
// Dataset Sampling & Description                       [264w, 0.5p] +40
// Operationalization & Measure                         [500w. 1p]   +142
// Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p] +20
// Networkanalysis (Threads, Replynetwork, ego networks) [295w, 0.6p] +38
//                                                                   +762	
// Summary                                             [100w, 0.2 p] +33


//== Introduction                                        [100w, 0.2p]
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

//== Dataset Sampling & Description                       [264w, 0.5p] 
//#lorem(264) +40words
== Data and Operationalization

The dataset used in this study was kindly provided by Armin Pournaki from the Max Planck Institute for Mathematics in the Sciences, Leipzig. 
//#text(fill: red)[did armin use this data somewhere in his own studies?? maybe I can cite something] 
The dataset holds tweets and replies directed at German members of parliament aswell as their retweets and referenced tweets, collected over a one wekk from February 7 to February 14, 2022. Only the MPs tweets and their replies are analysed since the reply network best captures social interactions of engagementcommunities. Data were obtained via Twitter's streaming API using two parallel strategies. The follow stream tracked replies to MP-generated tweets, while the track stream captured tweets mentioning MP handles (e.g., #quote[\@username]), including direct and nested replies. Protected accounts were excluded. Both datasets were combined and deduplicated. From the raw data, reply-threads were constructed by linking tweets through directed reply chains. These interactions were then aggregated to a user-level reply network, weighted by the number of exchanges. Thus, the dataset enables an analysis of interaction patterns between politicians and their engagement communities on social media.
To deliniate the set of politicians and add their name and party information, a list of parliamentary members of the 19th, 20th, and 21st German Bundestag is obtained from the Bundestags Webarchiv and added to the original dataset through their twitter-account links @bundestag2026. The complete dataset consists of 693 015 Tweets in the twitwi format @medialab2026.

German political news from 7–14 February 2022 were dominated by the Omikron wave's peak and the escalating Russia-Ukraine crisis. As Russia massed troops for what would become Europe's largest military offensive since WWII, Chancellor Scholz met President Biden to discuss Germany's Nord Stream 2 dependency. Domestically, Scholz's coalition split over a general vaccine mandate, with FDP Justice Minister Buschmann deeming it constitutionally dubious and proposing mandatory physician consultations for unvaccinated adults as a softer alternative.


//== Operationalization & Measure                         [500w. 1p]
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
Politicians using populist strategies on social media do not have to adress all populism dimensions in one tweet but can be anti-elitist in one and pro-people in the next. Therefore the combination on the user level is achieved by averaging each dimension separately before recombining. Let $macron(p)_u$, $macron(e)_u$, and $macron(a)_u$ denote the per-user means. The user-level score is

$ "Populism"_u = cases(
  (macron(p)_u - macron(e)_u) times macron(a)_u & "if" macron(p)_u > 0 comma macron(e)_u < 0 comma macron(a)_u > 0,
  macron(p)_u - macron(e)_u & "if" macron(p)_u > 0 comma macron(e)_u < 0 comma macron(a)_u = 0,
  0 & "otherwise"
) $

The gate zeros out users whose average rhetoric is not simultaneously people-affirming and elite-critical, operationalizing #cite(<mudde2004>,form: "prose")'s tripart definition at the actor level. Aggregating dimensions before recombining allows a user to distribute their anti-elite and pro-people attitudes across different tweets.


//== Textanalysis (Discuss LLM, Prompt, Validation)       [332w, 0.6p]
//#lorem(332) +20words
== Textanalysis
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




//== Networkanalysis (Threads, Replynetwork, ego networks) [295w, 0.6p]	
//#lorem(295) +38words

== Network Analysis
The reply threads are constructed by treating tweets as nodes that are linked through directed replies. A component in the constructed thread network is then a replythread with one rootnode that is only recieving links marking the direction of a reply. Some reply chains trace back to MP tweets posted before the collection period, so the root node has no row in the dataset. Matching the target tweets user information against the politician table recovers their authorship, recovering 2,631 of 89,561 threads (2.9%). Threads root tweet information like politician with e.g. party and followerinformation, are then stored within the reply tweets of the respective thread and aswell added to each tweet in the reply network. 

The main research question requires a network of interactions plausibly representing an engagement community. A weighted user centric reply network with users as nodes and replies as directed links is constructed. The original tweet-based dataset holding politician and threadinformation served as the basis for construction with its `user_id` and `to_userid` variables. The resulting network is directed with edgeweights based on replycount. It holds 81 295 user-nodes connected through 239 502 reply-links distributed among 1865 components. A giant component holds (77 194) 94% of all nodes. 1207 users are contained in components of size 2, one original user, one replying user, as the threadsize holding the second most nodes. The second largest component held 41 (0.05%) users (see the #link(<sec:app-component-table>)[table] in appendix).
The network analysis is based on the giant component to make computation more feasable leading to a loss of the network periphery without any actual structurally relevant threads.

Tweet-level populism dimensions (people scores, elitism scores, antagonism scores) are aggregated per user by computing weighted means across each user's tweets, then combined into a userlevel composite populism score. These user-level scores are added as vertex attributes to the reply network.

To definitly deliniate the dataset to replies from politicians tweets reply-edges not appearing underneath politicians threads are deleted and isolates are removed. Thereby removing rest-replythreads of e.g. referenced tweets.


//== OOPS I FORGOT THE SECTION WITH MY MODELS WHEN STRUCTURING MY PARAGRAPHS/WORDS + 510w
//+762words
== Ego Network Analysis
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

//== Summary                                             [100w, 0.2 p]
//#lorem(100) +33
/*
This section described the data, measures, and analytical strategy used to examine how populist rhetoric by German MPs shapes their engagement communities on Twitter. 
The dataset comprises 693,015 tweets collected via Twitter's streaming API from 7-14 February 2022. 
Populism is operationalized as People Attitude, Elite Attitude, and Antagonism, scored by Qwen3-235B using a chain-of-thought annotation prompt validated against the PopBERT expert corpus. 
Reply threads are reconstructed into a weighted user-level network whose giant component (77,194 nodes, 239,502 edges) serves as the analytical base. 
Two OLS models regress mean alter degree on a binary populism indicator with controls for ego degree, follower count, and mean thread size. As a second dependent variable the ego networks fragmentation ratio provides a robustness check. Further exploration of alter-alter connection compares userbehaviour of populist and non-populist ego networks  
*/


















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



//== Introduction                     [100w, 0.2p]
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

- 2 tweetbeispiele zeigen (philipp sagt ich soll)
- keine struktur ==> wir brauchen advancte methoden
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
