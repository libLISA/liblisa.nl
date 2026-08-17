#import "../theme.typ": *
#import "@preview/thmbox:0.3.0": *

#show: thmbox-init(counter-level: 1)

#set cite(style: "springer-lecture-notes-in-computer-science")

#set par(
  justify: true,
  leading: .52em,
  spacing: .52em,
  first-line-indent: (amount: 1.5em, all: true),
)

#show raw: it => {
  rect(
    stroke: none,
    fill: black.transparentize(95%),
    inset: (top: 3mm, bottom: 3mm, left: 6mm, right: 6mm),
    [
      #it
    ]
  )
}

#show figure.caption: it => {
  let numbering = if it.numbering != none {
    [~] + context it.counter.display(it.numbering)
  }
  emph[*#it.supplement#numbering#it.separator*#it.body]
}

#show figure: it => {
  block(inset: (top: 3mm, bottom: 3mm, left: 0mm, right: 0mm), it)
}

#show grid: it => {
  html.frame(it)
}

#set table(inset: .3em)
#set table(
  inset: (left: 3pt, right: 3pt, top: 5pt, bottom: 5pt),
  stroke: none,
  align: (x, y) => if x == 0 { left } else { center } + horizon,
  fill: (_, y) => if y == 0 { liblisa-blue } else if calc.even(y) { liblisa-blue.lighten(93%) },
)

#show table: it => {
  set text(size: 9pt)
  rect(
    inset: 0.5pt,
    stroke: 1pt + liblisa-blue,
    it
  )
}

#show table.cell.where(y: 0): set text(weight: "bold", fill: white)

#show outline: body => {
  show outline.entry.where(level: 1): set block(above: 1.5em)
  show outline.entry.where(level: 1): set text(weight: "bold")
  show outline.entry.where(level: 1): set outline.entry(fill: none)
  set outline.entry(fill: pad(left: 0.2em, right: 1em, repeat(gap: 0.50em, [.])))
  show outline.entry: it => link(
    it.element.location(),
    if it.prefix() == none {
      it.indented(none, it.inner())
    } else {
      it.indented(it.prefix(), it.inner())
    },
  )

  body
}

#show heading: it => {
  if target() != "html" and it.level == 1 {
    pagebreak(weak: true)
  }

  // Increase distance between heading and surrounding paragraphs.
  set block(above: 2em, below: if target() == "html" {
    1em
  } else {
    1.6em
  })

  // Increase distance between numbering and heading.
  if it.numbering == none {
    block(it.body)
  } else {
    if target() == "html" [
      #it
    ] else [
      #block[
        #std.numbering(it.numbering, ..counter(heading).at(it.location()))
        #h(0.8em)
        #it.body
      ]
    ]
  }
}

#show list: body => {
  block(
    inset: (left: 1.1em),
    body
  )
}

#show enum: body => {
  block(
    inset: (left: 1.1em),
    body
  )
}

#show ref: it => {
  let el = it.element
  if el == none or el.func() != heading or el.level != 1 { return it }
  let heading-levels = counter(heading).at(el.location())
  let body = numbering(n => [#el.supplement #n], ..heading-levels)
  link(el.location(), body)
}

#let insert-metadata = context[
  #html.elem("div", attrs: (id: "previous-page", style: "display: none"), {
    let headings = query(heading.where(level: 1).before(here()))
    if headings.len() > 0 {
      let h = headings.last()
      link(h.location())[ #h.body ]
    }
  })

  #html.elem("div", attrs: (id: "next-page", style: "display: none"), {
    let headings = query(heading.where(level: 1).after(here()))
    if headings.len() > 1 {
      let h = headings.at(1)
      link(h.location())[ #h.body ]
    }
  })
]

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