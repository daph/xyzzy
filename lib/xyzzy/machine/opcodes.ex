defmodule Xyzzy.Machine.Opcodes do
  import Xyzzy.Machine.Decoding
  alias Xyzzy.Machine.StateServer, as: StateServer

  # op-call
  def opcode(0xe0, state_pid, ret, [r|rargs]) when r != 0 do
    state = StateServer.get_state(state_pid)
    routine = unpack!(r, state.version)
    new_locals =
      routine
      |> decode_routine_locals(state)
      |> Enum.drop(length(rargs))
      |> (&(Enum.concat(rargs, &1))).()
      |> (&(Enum.zip(1..length(&1), &1))).()
      |> Enum.into(%{})

    StateServer.push_call_stack(state_pid, ret)
    StateServer.set_pc(state_pid, (routine+1+(2*map_size(new_locals))))
    StateServer.set_locals(state_pid, new_locals)
    StateServer.clear_stack(state_pid)
  end

  # op-add
  def opcode(op, state_pid, ret, args) when op in [0x54, 0x74] do
    math_op(&+/2, ret, args, state_pid)
  end

  # op-sub
  def opcode(op, state_pid, ret, args) when op in [0x55, 0x75] do
    math_op(&-/2, ret, args, state_pid)
  end

  defp math_op(func, ret, [a1, a2], state_pid) do
    val = func.(a1, a2)
    %{memory: mem} = StateServer.get_state(state_pid)
    mem
    |> :binary.at(ret)
    |> write_variable(val, state_pid)

    StateServer.set_pc(state_pid, ret+1)
  end
end
