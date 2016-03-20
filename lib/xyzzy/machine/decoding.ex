defmodule Xyzzy.Machine.Decoding do
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
  def decode_opcode(_state = %{memory: mem, pc: pc}) do #WIP
    :binary.at(mem, pc) |> decode_form
  end

  def decode_form(op) when op in 0x00..0x1f, do: {:op2, {:sc, :sc}}
  def decode_form(op) when op in 0x20..0x3f, do: {:op2, {:sc, :v}}
  def decode_form(op) when op in 0x40..0x5f, do: {:op2, {:v, :sc}}
  def decode_form(op) when op in 0x60..0x7f, do: {:op2, {:v, :v}}
  def decode_form(op) when op in 0x80..0x8f, do: {:op1, {:lc}}
  def decode_form(op) when op in 0x90..0x9f, do: {:op1, {:sc}}
  def decode_form(op) when op in 0xa0..0xaf, do: {:op1, {:v}}
  def decode_form(op) when op == 0xbe, do: {:ext, {:nb}}
  def decode_form(op) when op in 0xb0..0xbf, do: {:op1, {:o}}
  def decode_form(op) when op in 0xc0..0xdf, do: {:op2, {:nb}}
  def decode_form(op) when op in 0xe0..0xff, do: {:var, {:nb}}

  # For decoding VAR and EXT type bytes.
  def decode_nb(typebyte) do
    for << x :: 2 <- <<typebyte>> >> do
      case x do
        0 -> :lc
        1 -> :sc
        2 -> :v
        3 -> :o
      end
    end
  end
end
