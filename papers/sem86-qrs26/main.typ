#import "../theme.typ": *
#import "@preview/thmbox:0.3.0": *

#show: thmbox-init(counter-level: 1)
#show: liblisa-style

#document("index.html", title: [ #sem86: A Full-System Emulator Without Hard-Coded Semantics ], [
  #include "abstract.typ"

  #html.elem(
    "div",
    attrs: (class: "footnote"),
  )[
    This is the author's version of the work posted here per the publisher's guidelines for your personal use.
    Not for redistribution.
    The final authenticated version is published in the Proceedings of the 26th International Conference on Software Quality,
    Reliability, and Security (QRS 2026), Florence, Italy, July 22-25, 2026.
  ]
])

#document("01-introduction.html", title: "Introduction", [
  #insert-metadata
  #include "introduction.typ"
])

#document("02-related-work.html", title: "Related Work", [
  #insert-metadata
  #include "related-work.typ"
])

#document("03-implementation.html", title: "Implementation", [
  #insert-metadata
  #include "implementation.typ"
])

#document("04-evaluation.html", title: "Evaluation", [
  #insert-metadata
  #include "evaluation.typ"
])

#document("05-discussion.html", title: "Discussion and Conclusion", [
  #insert-metadata
  #include "discussion.typ"
])

#document("06-bibliography.html", title: "Acknowledgements, Data-availabilty and References", [
  #insert-metadata

  = Acknowledgements, Data-availabilty and References
  == Acknowledgements
  This paper is based upon work supported by the Defense Advanced Research Projects Agency (DARPA) and Naval Information Warfare Center Pacific (NIWC Pacific) under Prime Contract No. N66001-21-C-4028, and by DARPA under Prime Contract No. HR001124C0492. Any views, opinions, findings, and conclusions or recommendations expressed in this paper are those of the authors and should not be interpreted as presenting the official policies or position, either expressed or implied, of DARPA or the U.S. Government. The U.S. Government is authorized to reproduce and distribute reprints of publications for Government purposes notwithstanding any copyright notation hereon.

  == Data-availability statement
  All source code is available on #link("https://liblisa.nl/sem86") under the AGPLv3 open source license.

  == References
  #bibliography(title: none, "../all.bib")
])