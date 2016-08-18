defmodule Xyzzy.Machine.OpInfo do
  defstruct operands: [],
            operand_types: [],
            next_pc: nil,
            return_store: nil,
            branch_addr: nil,
            branch_cond: nil
end
