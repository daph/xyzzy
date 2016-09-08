defmodule OpcodeExample do

  # Define and opcode with name "dec-chk"
  # with the hex representation of 0x45
  # and get context.
  opcode "dec-chk", [0x45], context do
    [var, chk] = context[:operands]
    chk_val = make_signed(chk)
    var_val =
      var
      # read_var is a macro that modifies the state internall if need be
      # (like for popping of the stack, but here it's indirect)
      |> read_var(indirect: true)
      |> make_signed
      |> &(&1-1).()

    write_var(var, var_val, indirect: true)

    if var_val < chk_val do
      set_pc(context[:branch_addr])
    end
  end

  # Notice there is no passing around of the "state" variable.
  # The thought is to design an opcode DSL that acts like an
  # imperative language since that's how opcodes work. They are
  # a bunch of statements that change the state.
  #
  # It gets a little unweildly passing around a state structure or
  # state handle (to a pid with the state) to every little function
  # since any one could change the state. Take something as simple as
  # reading a variable, that could pop the stack and so modifies the state
  # so it requires a handle the state process or the state structure just to
  # read a variable.
  #
  # We can also pull some tricks that would look terrible in code with an opcode DSL
  # like being able to roll them all up as pattern matched functions (similar to how
  # I was doing things in the beginning), so we wouldn't need some large map to look up
  # each function.
end
