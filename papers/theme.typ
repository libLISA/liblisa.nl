#import "@preview/thmbox:0.3.0": *
#import "@preview/algorithmic:1.0.7": style-algorithm, algorithm as algorithmic_internal
#import "@preview/subpar:0.2.2"
#show: style-algorithm

#let in-math = state("in-math", false)
#let default-font = "Latin Modern Roman";
#let liblisa-blue = rgb("#1c5dcf");
#let libLISA = smallcaps("libLISA")
#let sem86 = smallcaps("Sem86")
#let num(n) = [ #n ]
#let tt(body) = context {
  if target() == "html" and not in-math.get() {
    html.code(body)
  } else {
    text(font: "Latin Modern Mono", body)
  }
}

#let paragraph(title) = {
  text(weight: "bold", title + ".")
}

#let example = example.with(color: liblisa-blue)

#let y = sym.checkmark
#let n = sym.crossmark

#let actual_label = label

#let avg(nums) = nums.sum() / nums.len()

#let contains-table(elem) = {
  if elem.func() == table {
    true
  } else if elem.has("children") {
    elem.children.any(contains-table)
  } else if elem.has("body") {
    contains-table(elem.body)
  } else {
    false
  }
}

#let contains-raw(elem) = {
  if elem.func() == raw {
    true
  } else if elem.has("children") {
    elem.children.any(contains-raw)
  } else if elem.has("body") {
    contains-raw(elem.body)
  } else {
    false
  }
}

#let html-compatible-figure(
  body,
  label: none,
  framed: false,
  ..rest
) = context {
  let named = rest.named()
  if "kind" not in named {
    named.kind = if contains-table(body) {
      "table"
    } else {
      "figure"
    }
  }

  if "supplement" not in named {
    named.supplement = if named.kind == "figure" {
      "Figure"
    } else if named.kind == "table" {
      "Table"
    } else {
      panic("Unknown kind: " + named.kind)
    }
  }

  [
    #figure(
      if target() == "html" and framed {
        html.frame(body)
      } else {
        block(body)
      },
      ..named
    ) #label
  ]
}

#let html-compatible-multifigure(
  ..figures,
  columns: (auto),
  caption: [],
  label: none,
  kind: "figure",
  supplement: "Figure",
) = {
  set align(top)
  let inner = subpar.grid(
    grid-styles: it => {
      set std.grid(gutter: 1em, align: top)
      it
    },
    ..figures.pos().map(((body, label)) => {
      (body, label)
    }).flatten(),
    columns: columns,
    caption: caption,
    label: label,
    kind: kind,
    supplement: supplement,
  )

  context {
    if target() == "html" {
      html.frame(
        block(width: 16cm, inner)
      )
    } else {
      inner
    }
  }
}

#let algorithmic(..args) = {
  html.frame(
    block(width: 16cm,
      algorithmic_internal(..args)
    )
  )
}

#let algorithm(title: [], body, label: none) = html-compatible-figure(
  kind: "algorithm",
  supplement: "Algorithm",
  caption: title,
  label: label,
  body
)

#let framed(inner) = context {
  if target() == "html" {
    html.frame(inner)
  } else {
    inner
  }
}

#let html-h(size) = context {
  if target() == "html" {
    html.span(style: "display: inline-block; width: " + str(size.em) + "em", " ")
  } else {
    h(size)
  }
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

#let example = example.with(numbering: "1")

#let liblisa-style(it) = {
  show math.equation: it => in-math.update(true) + it + in-math.update(false)

  show h: it => context {
    if target() == "html" and type(it.amount) == length {
      html.span(style: "display: inline-block; width: " + str(it.amount.em) + "em", " ")
    } else {
      it
    }
  }

  set cite(style: "springer-lecture-notes-in-computer-science")

  set par(
    justify: true,
    leading: .52em,
    spacing: .52em,
    first-line-indent: (amount: 1.5em, all: true),
  )

  show raw: it => {
    block(
      stroke: none,
      fill: black.transparentize(95%),
      inset: (top: 3mm, bottom: 3mm, left: 6mm, right: 6mm),
      [
        #it
      ]
    )
  }

  show figure.caption: it => {
    let numbering = if it.numbering != none {
      [~] + context it.counter.display(it.numbering)
    }
    emph[*#it.supplement#numbering#it.separator*#it.body]
  }

  show figure: it => {
    block(inset: (top: 3mm, bottom: 3mm, left: 0mm, right: 0mm), it)
  }

  show grid: it => {
    html.frame(it)
  }

  set table(inset: .3em)
  set table(
    inset: (left: 3pt, right: 3pt, top: 5pt, bottom: 5pt),
    stroke: none,
    align: (x, y) => if x == 0 { left } else { center } + horizon,
    fill: (_, y) => if y == 0 { liblisa-blue } else if calc.even(y) { liblisa-blue.lighten(93%) },
  )

  show table: it => {
    set text(size: 9pt)
    block(
      inset: 0.5pt,
      stroke: 1pt + liblisa-blue,
      it
    )
  }

  show table.cell.where(y: 0): set text(weight: "bold", fill: white)

  show outline: body => {
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

  show heading: it => {
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

  show list: body => {
    block(
      inset: (left: 1.1em),
      body
    )
  }

  show enum: body => {
    block(
      inset: (left: 1.1em),
      body
    )
  }

  show ref: it => {
    let el = it.element
    if el == none or el.func() != heading or el.level != 1 { return it }
    let heading-levels = counter(heading).at(el.location())
    let body = numbering(n => [#el.supplement #n], ..heading-levels)
    link(el.location(), body)
  }
  
  it
}