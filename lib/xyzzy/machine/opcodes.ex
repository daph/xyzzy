defmodule Xyzzy.Machine.Opcodes do
  import Xyzzy.Machine.Decoding

  alias Xyzzy.Machine.State

  # op-call
  def opcode(0xe0, game_name, ret, args = [r|_]) when r != 0 do
   call(game_name, ret, args)
  end
  # op-je
#  def opcode(op, game_name, ret, args) when op in [0x41, 0x61, 0xc1] do
    # jump_if
#  end
  # op-add
  def opcode(op, game_name, ret, args) when op in [0x54, 0x74] do
    math_op(&+/2, ret, args, game_name)
  end
  # op-sub
  def opcode(op, game_name, ret, args) when op in [0x55, 0x75] do
    math_op(&-/2, ret, args, game_name)
  end
  # op-mul
  def opcode(op, game_name, ret, args) when op in [0x56, 0x76] do
    math_op(&*/2, ret, args, game_name)
  end
  # op-div
  def opcode(op, game_name, ret, args) when op in [0x57, 0x77] do
    math_op(&div/2, ret, args, game_name)
  end
  # op-mul
  def opcode(op, game_name, ret, args) when op in [0x58, 0x78] do
    math_op(&rem/2, ret, args, game_name)
  end

  defp call(game_name, ret, [r|rargs]) do
    state = State.Server.get_state(game_name)
    routine = unpack!(r, state.version)
    new_locals =
      routine
      |> decode_routine_locals(state)
      |> Enum.drop(length(rargs))
      |> (&(Enum.concat(rargs, &1))).()
      |> (&(Enum.zip(1..length(&1), &1))).()
      |> Enum.into(%{})

    State.Server.push_call_stack(game_name, ret)
    State.Server.set_pc(game_name, (routine+1+(2*map_size(new_locals))))
    State.Server.set_locals(game_name, new_locals)
    State.Server.clear_stack(game_name)
  end

  defp math_op(func, ret, [a1, a2], game_name) do
    sa1 = make_signed(a1)
    sa2 = make_signed(a2)
    val = func.(sa1, sa2)
    %State{memory: mem} = State.Server.get_state(game_name)
    mem
    |> :binary.at(ret)
    |> write_variable(val, game_name)

    State.Server.set_pc(game_name, ret+1)
  end

  defp jump_if(func, ret, args, game_name) do
    %State{memory: mem} = State.Server.get_state(game_name)
    label = :binary.at(mem, ret) |> :binary.encode_unsigned
    # First bit (tf), is if we jump if true (1) or false (0)
    # Second bit (l), is if the offset is one byte (1) or two (0)
    # rest is the offset (or first half if `l` is set)
    << tf :: 1, l :: 1, rest :: 6 >> = label

    offset =
      case l do
        1 ->
          State.Server.set_pc(game_name, ret)
          rest
        0 ->
          State.Server.set_pc(game_name, ret+1)
          rest + :binary.at(mem, ret+1)
      end

    jmp_cond =
      case tf do
        1 -> true
        0 -> false
      end

    %State{pc: pc} = State.Server.get_state(game_name)
    if func.(args) == jmp_cond do
      State.Server.set_pc(game_name, pc+offset-1)
    else
      State.Server.set_pc(game_name, pc+1)
    end
  end
end
