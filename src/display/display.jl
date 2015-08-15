using Media, Lazy, Hiccup

import Media: render

type Inline end

for D in :[Editor, Console].args
  @eval type $D end
  @eval let pool = @d()
    Media.pool(::$D) = merge(Media.pool(), pool)
    Media.setdisplay(::$D, T, input) = pool[T] = input
  end
end

setdisplay(Editor(), Any, Console())
setdisplay(Console(), Any, Console())

# Inline display

type Tree
  head
  children::Vector{Any}
end

tojson(x) = stringmime(MIME"text/html"(), x)
tojson(t::Tree) = Any[tojson(t.head), map(tojson, t.children)]

render(i::Inline, t::Tree; options = @d()) = t

render(::Inline, x::HTML; options = @d()) = x

render(::Inline, x::Node; options = @d()) = x

# Console

render(::Console, x; options = @d()) =
  println(stringmime(MIME"text/plain"(), x))

render(::Console, ::Nothing; options = @d()) = nothing

# Editor

render(e::Editor, ::Nothing; options = @d()) =
  render(e, Text("✓"), options = options)

render(::Editor, x; options = @d()) =
  render(Inline(), x, options = options)

include("objects.jl")
