defmodule Xyzzy.Machine.OpFuncs do
  import Xyzzy.Machine.Decoding

  alias Xyzzy.Machine.State
  alias Xyzzy.Machine.OpInfo

  def op_je(game_name, info) do
    func =
      fn [x|rest] ->
        Enum.any?(rest, &(x == &1))
      end
      jump_cond(func, info, game_name)
  end

  def op_jl(game_name, info = %OpInfo{operands: args}) do
    signed_args = Enum.map(args, &make_signed/1)
    func = fn [a,b] -> a < b end
    jump_cond(func, %{info | operands: signed_args}, game_name)
  end

  def op_jg(game_name, info = %OpInfo{operands: args}) do
    signed_args = Enum.map(args, &make_signed/1)
    func = fn [a,b] -> a > b end
    jump_cond(func, %{info | operands: signed_args}, game_name)
  end

  def op_add(game_name, info) do
    math_op(&+/2, info,  game_name)
  end

  def op_sub(game_name, info) do
    math_op(&-/2, info,  game_name)
  end

  def op_mul(game_name, info) do
    math_op(&*/2, info,  game_name)
  end

  def op_div(game_name, info) do
    math_op(&div/2, info,  game_name)
  end

  def op_mod(game_name, info) do
    math_op(&rem/2, info,  game_name)
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

  defp math_op(func, info = %OpInfo{operands: [a1, a2]}, game_name) do
    sa1 = make_signed(a1)
    sa2 = make_signed(a2)
    val = func.(sa1, sa2)

    write_variable(info.return_store, val, game_name)

    State.Server.set_pc(game_name, info.next_pc)
  end

  defp jump_cond(func, info, game_name) do
    if func.(info.operands) == info.branch_cond do
      State.Server.set_pc(game_name, info.branch_addr)
    else
      State.Server.set_pc(game_name, info.next_pc)
    end
  end
end
