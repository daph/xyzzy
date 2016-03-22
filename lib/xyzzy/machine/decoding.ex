defmodule Xyzzy.Machine.Decoding do

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

  # decode_opcode/1 takes in the current state, and returns the information
  # on what opcode it is, it's arguments, and the address after its end.
  def decode_opcode(state = %{memory: mem, pc: pc}) do #WIP
    operands =
      case mem |> :binary.at(pc) |> decode_form do
        {_, [:nb]} ->
          mem
          |> :binary.at(pc+1)
          |> decode_nb
          |> get_operands(%{state | :pc => pc+1})
        {_, f} -> get_operands(f, state)
      end
  end

  defp get_operands(op_types, %{memory: mem, pc: pc}) do
    len = Enum.reduce(op_types, 0, fn(x, acc) ->
      acc + Map.fetch!(@operand_sizes, x)
    end)
    mem
    |> :binary.part({pc+1, len})
    |> get_operands(op_types, [])
    |> Enum.reverse
  end

  defp get_operands(_, [], acc), do: acc
  defp get_operands(_, [:o|_], acc), do: acc
  defp get_operands(<<>>, _, acc), do: acc
  defp get_operands(bin, [h|t], acc) do
    s = Map.fetch!(@operand_sizes, h) * 8
    << x :: size(s), rest :: binary >> = bin
    get_operands(rest, t, [x|acc])
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

  def decode_routine_locals(routine, %{memory: mem, version: ver})
  when ver in 1..4 do
    local_num = :binary.at(mem, routine)
    locals = :binary.part(mem, {routine+1, 2*local_num})
    for << x :: 16 <- locals >>, do: x
  end
end
