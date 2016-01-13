global sock = nothing

isactive(sock::Void) = false
isactive(sock) = isopen(sock)

macro ierrs(ex)
  :(try
      $(ex)
    catch e
      msg("error", @d(:msg=>"Julia Client – Internal Error",
                      :detail=>sprint(showerror, e, catch_backtrace()),
                      :dismissable=>true))
    end)
end

function connect(port)
  exit_on_sigint(false)
  global sock = Base.connect(port)
  @async while isopen(sock)
    @ierrs let # Don't let tasks close over the same t, data
      t, data = JSON.parse(sock)
      @schedule @ierrs handlemsg(t, data)
    end
  end
end

function msg(t, data)
  isactive(sock) || return
  println(sock, json(c(t, data)))
end

const handlers = Dict{UTF8String, Function}()

handle(f, t) = handlers[t] = f

id = 0
const callbacks = Dict{Int,Condition}()

function rpc(t, args...)
  i, c = (global id += 1), Condition()
  callbacks[i] = c
  msg(t, d(:callback => i, :args => args))
  return wait(c)
end

function handlemsg(t, data)
  result, id = nothing, nothing
  if isa(data, Associative)
    haskey(data, "callback") && (id = data["callback"])
    delete!(data, "callback")
  end
  if haskey(handlers, t)
    result = handlers[t](data)
  elseif haskey(callbacks, t)
    notify(callbacks[t], data)
    delete!(callbacks, t)
  else
    warn("Atom.jl: unrecognised message $t.")
  end
  isa(id, Integer) && msg(id, result)
end

isconnected() = sock ≠ nothing && isopen(sock)
