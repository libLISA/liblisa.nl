#import "../theme.typ": *
#import "@preview/thmbox:0.3.0": *

#show: liblisa-style
#show: thmbox-init(counter-level: 1)

#document("index.html", title: "libLISA: Instruction Discovery and Analysis on x86-64", [
  #include "abstract.typ"
])

#document("01-introduction.html", title: "Introduction", [
  #insert-metadata
  #include "introduction.typ"
])

#document("02-overview.html", title: "Overview", [
  #insert-metadata
  #include "overview.typ"
])

#document("03-related-work.html", title: "Related Work", [
  #insert-metadata
  #include "related-work.typ"
])

#document("04-approach.html", title: "Approach", [
  #insert-metadata
  #include "approach.typ"
])

#document("05-results.html", title: "Results", [
  #insert-metadata
  #include "results.typ"
])

#document("07-discussion.html", title: "Discussion", [
  #insert-metadata
  #include "discussion.typ"
])

#document("08-bibliography.html", title: "Acknowledgements, Data-availabilty and References", [
  #insert-metadata

  = Acknowledgements, Data-availabilty and References
  == Acknowledgements
  We thank the anonymous reviewers for their insightful comments, which have greatly improved the paper.

  This work is supported by the Defense Advanced Research Projects Agency (DARPA) and Naval Information Warfare Center Pacific (NIWC Pacific) under Contract No. N66001-21-C-4028.

  == Data-availability statement
  The analysis results are available in an easily browsable format on #link("https://explore.liblisa.nl/").
  The #libLISA implementation is available under the AGPLv3 open source license on #link("https://github.com/liblisa").
  A self-contained reproduction package is available on Zenodo @zenodo.

  == References
  #bibliography(title: none, "../all.bib")
])