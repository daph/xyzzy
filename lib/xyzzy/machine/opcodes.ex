defmodule Xyzzy.Machine.Opcodes do
  import Xyzzy.Machine.Decoding

  def op_call(state, args) do
    routine = unpack(hd(args), state.version)
    
  end
end
