defmodule Xyzzy.Machine.OpFuncs do
  import Xyzzy.Machine.Decoding

  alias Xyzzy.Machine.State
  alias Xyzzy.Machine.OpInfo

  # op-je
  def op_je(game_name, info) do
    func =
      fn [x|rest] ->
        Enum.any?(rest, &(x == &1))
      end
      #    jump_cond(func, info, game_name)
  end
  # op-jl
  def opcode(op, game_name, ret, args) when op in [0x42, 0x62, 0xc2] do
    signed_args = Enum.map(args, &make_signed/1)
    func = fn [a,b] -> a < b end
    #jump_cond(func, ret, signed_args, game_name)
  end
  # op-jg
  def opcode(op, game_name, ret, args) when op in [0x43, 0x63, 0xc3] do
    signed_args = Enum.map(args, &make_signed/1)
    func = fn [a,b] -> a > b end
    #jump_cond(func, ret, signed_args, game_name)
  end
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
  # op-mod
  def opcode(op, game_name, ret, args) when op in [0x58, 0x78] do
    math_op(&rem/2, ret, args, game_name)
  end

  def op_call(game_name, info = %OpInfo{operands: [r|rargs]}) when r != 0 do
    state = State.Server.get_state(game_name)
    routine = unpack!(r, state.version)
    new_locals =
      routine
      |> decode_routine_locals(state)
      |> Enum.drop(length(rargs))
      |> (&(Enum.concat(rargs, &1))).()
      |> (&(Enum.zip(1..length(&1), &1))).()
      |> Enum.into(%{})

    State.Server.push_call_stack(game_name, info.next_pc, info.return_store)
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

  defp jump_cond(func, ret, args, game_name) do
    %State{memory: mem} = State.Server.get_state(game_name)

    %State{pc: pc} = State.Server.get_state(game_name)
    if func.(args) == jmp_cond do
      State.Server.set_pc(game_name, pc+offset-1)
    else
      State.Server.set_pc(game_name, pc+1)
    end
  end
end
