#import "@preview/thmbox:0.3.0": *
#import "@preview/algorithmic:1.0.7": style-algorithm, algorithm as algorithmic_internal
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