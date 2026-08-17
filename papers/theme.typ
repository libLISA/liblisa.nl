#import "@preview/thmbox:0.3.0": *
#import "@preview/algorithmic:1.0.7": style-algorithm, algorithm as algorithmic_internal
#import "@preview/subpar:0.2.2"
#show: style-algorithm

#let default-font = "Linux Libertine O";
#let liblisa-blue = rgb("#1c5dcf");
#let libLISA = smallcaps("libLISA")
#let sem86 = smallcaps("Sem86")
#let num(n) = [ #n ]
#let tt(body) = text(font: "Linux Libertine Mono O", body)

#let paragraph(title) = {
  text(weight: "bold", title + ".")
}

#let example = example.with(color: liblisa-blue)

#let y = sym.checkmark
#let n = sym.crossmark

#let avg(nums) = nums.sum() / nums.len()
#let html-compatible-figure(
  body,
  ..rest
) = {
  figure(
    html.frame(body),
    ..rest
  )
}

#let html-compatible-multifigure(
  ..figures,
  columns: (auto),
  caption: [],
  label: none,
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

#let algorithm(title: [], body) = html-compatible-figure(
  kind: "algorithm",
  supplement: "Algorithm",
  caption: title,
  body
)