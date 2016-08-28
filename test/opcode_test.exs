defmodule OpcodeTest do
  alias Xyzzy.Machine.OpFuncs
  alias Xyzzy.Machine.OpInfo
  alias Xyzzy.Machine.State

  use ExUnit.Case
  doctest Xyzzy

  setup_all do
    {:ok, _pid} = State.Registry.start_link
    {:ok, _pid} = State.Supervisor.start_link

    :ok
  end

  setup context do
    state_name = "#{context[:test]}_test"
    case context[:op_type] do
      "math-op" ->
        state = %State{locals: %{2 => 0}}
        info = %OpInfo{operands: [65525, 5],
                       next_pc: 0xBEEF,
                       return_store: 0x02}
        State.Supervisor.start_game(state, state_name)
        on_exit fn -> State.Server.stop(state_name) end
        {:ok, [state_name: state_name, info: info,
               next_pc: 0xBEEF, result: 65530]}

      _ -> {:ok, [state_name: state_name]}

    end
  end

  @tag op_type: "math-op"
  test "op_add", context do
    OpFuncs.op_add(context[:state_name], context[:info])

    state = State.Server.get_state(context[:state_name])

    assert state.pc == context[:next_pc]
    assert state.locals |> Map.get(2) == context[:result]
  end
end
