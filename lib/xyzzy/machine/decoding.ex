defmodule Xyzzy.Machine.Decoding do
  alias Xyzzy.Machine.State
  alias Xyzzy.Machine.StateServer

  @operand_sizes %{:sc => 1, :lc => 2, :v => 1, :o => 0}

  # unpack/2 will unpack packed addresses for versions 1-5, and 8.
  # Versions 6 and 7 require a different formula, where there are
  # offsets supplied in the header for routines and strings.
  def unpack(address, version) when version in 1..3 do
    {:ok, 2 * address}
  end
  def unpack(address, version) when version in [4,5] do
    {:ok, 4 * address}
  end
  def unpack(address, 8), do: {:ok, 8 * address}
  def unpack(_address, _version), do: {:error, :version_not_supported}

  def unpack!(address, version) do
    {:ok, addr} = unpack(address, version)
    addr
  end

  # decode_opcode/1 takes in the current state, and returns the information
  # on what opcode it is, it's arguments, and the address after its end.
  def decode_opcode(state = %State{memory: mem, pc: pc}) do
      case mem |> :binary.at(pc) |> decode_form do
        {_, [:nb]} ->
          mem
          |> :binary.at(pc+1)
          |> decode_nb
          |> get_op_info(%{state | :pc => pc+1})
        {_, f} -> get_op_info(f, state)
      end
  end

  defp get_oplen(op_types) do
    Enum.reduce(op_types, 0, fn(x, acc) ->
      acc + Map.fetch!(@operand_sizes, x)
    end)
  end

  # Gets all the info needed for a good, strong opcode to run.
  defp get_op_info(op_types, state) do
    end_addr = get_end_address(op_types, state)
    raw_operands = get_raw_operands(op_types, state)

    {raw_operands, op_types, end_addr}
  end

  # Gets the address after all the operands. This is sometimes the variable to
  # Store the return value, or just the next opcode.
  defp get_end_address(op_types, %State{pc: pc}) do
    len = get_oplen(op_types)
    pc+len+1
  end

  def get_operands(op_types, raw_operands, state_pid) do
    case :v in op_types do
      true -> get_operands(op_types, raw_operands, [], state_pid)
              |> Enum.reverse
      false -> raw_operands
    end
  end

  def get_operands([], [], acc, _state_pid), do: acc
  def get_operands(_op_types, [], acc, _state_pid), do: acc
  def get_operands([], _raw_operands, acc, _state_pid), do: acc
  def get_operands([type|tt], [op|ot], acc, state_pid) when type != :v do
    get_operands(tt, ot, [op|acc], state_pid)
  end
  def get_operands([_|tt], [op|ot], acc, state_pid) when op == 0x00 do
    val = StateServer.pop_stack(state_pid)
    get_operands(tt, ot, [val|acc], state_pid)
  end
  def get_operands([_|tt], [op|ot], acc, state_pid) when op in 0x01..0x0f do
    val = StateServer.get_local(state_pid, op)
    get_operands(tt, ot, [val|acc], state_pid)
  end
  def get_operands([_|tt], [op|ot], acc, state_pid) when op in 0x10..0xff do
    val = StateServer.get_global(state_pid, op)
    get_operands(tt, ot, [val|acc], state_pid)
  end

  defp get_raw_operands(op_types, %State{memory: mem, pc: pc}) do
    len = get_oplen(op_types)
    mem
    |> :binary.part({pc+1, len})
    |> get_raw_operands(op_types, [])
    |> Enum.reverse
  end

  defp get_raw_operands(_, [], acc), do: acc
  defp get_raw_operands(_, [:o|_], acc), do: acc
  defp get_raw_operands(<<>>, _, acc), do: acc
  defp get_raw_operands(bin, [h|t], acc) do
    s = Map.fetch!(@operand_sizes, h) * 8
    << x :: size(s), rest :: binary >> = bin
    get_raw_operands(rest, t, [x|acc])
  end

  defp decode_form(op) when op in 0x00..0x1f, do: {:op2, [:sc, :sc]}
  defp decode_form(op) when op in 0x20..0x3f, do: {:op2, [:sc, :v]}
  defp decode_form(op) when op in 0x40..0x5f, do: {:op2, [:v, :sc]}
  defp decode_form(op) when op in 0x60..0x7f, do: {:op2, [:v, :v]}
  defp decode_form(op) when op in 0x80..0x8f, do: {:op1, [:lc]}
  defp decode_form(op) when op in 0x90..0x9f, do: {:op1, [:sc]}
  defp decode_form(op) when op in 0xa0..0xaf, do: {:op1, [:v]}
  defp decode_form(op) when op == 0xbe, do: {:ext, [:nb]}
  defp decode_form(op) when op in 0xb0..0xbf, do: {:op1, [:o]}
  defp decode_form(op) when op in 0xc0..0xdf, do: {:op2, [:nb]}
  defp decode_form(op) when op in 0xe0..0xff, do: {:var, [:nb]}

  # For decoding VAR and EXT type bytes.
  defp decode_nb(typebyte) do
    for << x :: 2 <- <<typebyte>> >> do
      case x do
        0 -> :lc
        1 -> :sc
        2 -> :v
        3 -> :o
      end
    end
  end

  def decode_routine_locals(routine, %State{memory: mem, version: ver})
  when ver in 1..4 do
    local_num = :binary.at(mem, routine)
    locals = :binary.part(mem, {routine+1, 2*local_num})
    for << x :: 16 <- locals >>, do: x
  end

  def write_variable(var, val, state_pid) when var == 0x00 do
    StateServer.push_stack(state_pid, val)
  end
  def write_variable(var, val, state_pid) when var in 0x01..0x0f do
    StateServer.set_local(state_pid, var, val)
  end
  def write_variable(var, val, state_pid) when var in 0x10..0xff do
    StateServer.set_global(state_pid, var, val)
  end
end
