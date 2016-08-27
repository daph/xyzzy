defmodule OpcodeTest do
  alias Xyzzy.Machine.OpFuncs
  alias Xyzzy.Machine.OpInfo
  alias Xyzzy.Machine.State

  use ExUnit.Case
  doctest Xyzzy

  setup do
    {:ok, _pid} = State.Registry.start_link
    {:ok, _pid} = State.Supervisor.start_link
    :ok
  end

  test "op_add" do
    info = %OpInfo{operands: [2, 2],
                   next_pc: 0xBEEF,
                   return_store: 0x02}

    state = %State{locals: %{2 => 0}}
    State.Supervisor.start_game(state, "op_add_test")

    OpFuncs.op_add("op_add_test", info)

    state = State.Server.get_state("op_add_test")

    assert state.pc == 0xBEEF
    assert state.locals |> Map.get(2) == 4
  end
end
