defmodule Xyzzy.Machine do
  import Xyzzy.Machine.Decoding
  import Xyzzy.Machine.Opcodes

  def open_story(file) do
    case File.read(file) do
      {:ok, story} -> initalize_machine(story)
      {:error, _reason} -> IO.puts(:stderr, "Error opening file")
    end
  end

  defp initalize_machine(story = << version :: 8,
                                    flags1 :: 8,
                                    release :: 16,
                                    high_mem :: 16,
                                    pc :: 16,
                                    dictionary :: 16,
                                    object_table :: 16,
                                    global_start :: 16,
                                    static_mem :: 16,
                                    flags2 :: 16,
                                    _ :: 48,
                                    abbr_table :: 16,
                                    _ :: binary >>) do
    # 478 = 2 * (0xff - 16). 0xff being the last global var
    global_bin = :binary.part(story, {global_start, 478})
    global_vars =
      for << x :: 16 <- global_bin >> do x end
      |> (&(Enum.zip(0x10..0xff, &1))).()
      |> Enum.into(%{})
    %{:version => version,
      :flags1 => flags1,
      :release => release,
      :high_mem => high_mem,
      :pc => pc,
      :dictionary => dictionary,
      :object_table => object_table,
      :global_vars => global_vars,
      :static_mem => static_mem,
      :flags2 => flags2,
      :abbr_table => abbr_table,
      :memory => story,
      :stack => [],
      :call_stack => [],
      :locals => %{}}
  end

  def run_story(state_pid) do
    state = Xyzzy.Machine.StateServer.get_state(state_pid)
    {raw_operands, op_types, end_addr} = decode_opcode(state)
    operands = get_operands(op_types, raw_operands, state_pid)
    state.memory
    |> :binary.at(state.pc)
    |> opcode(state_pid, end_addr, operands)
  end
end
