defmodule Xyzzy.Machine.Decoding do
  # unpack/2 will unpack packed addresses for versions 1-5, and 8.
  # Versions 6 and 7 require a different formula, where there are
  # offsets supplied in the header for routinges and strings.
  def unpack(address, version) when version in 1..3 do
    2 * address
  end
  def unpack(address, version) when version in [4,5] do
    4 * address
  end
  def unpack(address, 8) do
    8 * address
  end
end
