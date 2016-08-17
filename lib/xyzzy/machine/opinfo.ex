defmodule Xyzzy.Machine.Opinfo do
  defstruct operands: [],
            operand_types: []
            next_pc: nil,
            return_store: nil,
            return_type: nil
end
