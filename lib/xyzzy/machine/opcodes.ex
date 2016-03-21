defmodule Xyzzy.Machine.Opcodes do
  import Xyzzy.Machine.Decoding

  def op_call(state, ret, [r|rargs]) when r != 0 do
    routine = unpack(r, state.version)
    new_locals =
      routine
      |> decode_routine_locals(state)
      |> Enum.drop(length(rargs))
      |> (&(Enum.concat(rargs, &1))).()
      |> (&(Enum.zip(1..length(&1), &1))).()

    %{state |
      :locals => new_locals,
      :stack => [],
      :pc => (routine + 1 + (2 * map_size(new_locals))),
      :call_stack => [%{:pc => state.pc, :locals => state.locals,
                        :stack => state.stack, :ret => ret}|state.call_stack]}
  end
end
