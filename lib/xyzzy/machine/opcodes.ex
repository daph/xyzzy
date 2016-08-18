defmodule Xyzzy.Machine.Opcodes do
  import Xyzzy.Machine.OpFuncs
  import Xyzzy.Machine.Decoding

  alias Xyzzy.Machine.Opcode

  @opmap %{
    # Long Form - 2OP - Small Constant, Small Constant
    0x01 => %Opcode{func: &op_je/2, indirect?: false, branch?: true},
    0x02 => %Opcode{func: &op_jl/2, indirect?: false, branch?: true},
    0x03 => %Opcode{func: &op_jg/2, indirect?: false, branch?: true},
    0x14 => %Opcode{func: &op_add/2, indirect?: false, branch?: false},
    0x15 => %Opcode{func: &op_sub/2, indirect?: false, branch?: false},
    0x16 => %Opcode{func: &op_mul/2, indirect?: false, branch?: false},
    0x17 => %Opcode{func: &op_div/2, indirect?: false, branch?: false},
    0x18 => %Opcode{func: &op_mod/2, indirect?: false, branch?: false},

    # Long Form - 2OP - Small Constant, Variable
    0x21 => %Opcode{func: &op_je/2, indirect?: false, branch?: true},
    0x22 => %Opcode{func: &op_jl/2, indirect?: false, branch?: true},
    0x23 => %Opcode{func: &op_jg/2, indirect?: false, branch?: true},
    0x34 => %Opcode{func: &op_add/2, indirect?: false, branch?: false},
    0x35 => %Opcode{func: &op_sub/2, indirect?: false, branch?: false},
    0x36 => %Opcode{func: &op_mul/2, indirect?: false, branch?: false},
    0x37 => %Opcode{func: &op_div/2, indirect?: false, branch?: false},
    0x38 => %Opcode{func: &op_mod/2, indirect?: false, branch?: false},

    # Long Form - 2OP - Variable, Small Constant
    0x41 => %Opcode{func: &op_je/2, indirect?: false, branch?: true},
    0x42 => %Opcode{func: &op_jl/2, indirect?: false, branch?: true},
    0x43 => %Opcode{func: &op_jg/2, indirect?: false, branch?: true},
    0x54 => %Opcode{func: &op_add/2, indirect?: false, branch?: false},
    0x55 => %Opcode{func: &op_sub/2, indirect?: false, branch?: false},
    0x56 => %Opcode{func: &op_mul/2, indirect?: false, branch?: false},
    0x57 => %Opcode{func: &op_div/2, indirect?: false, branch?: false},
    0x58 => %Opcode{func: &op_mod/2, indirect?: false, branch?: false},

    # Long Form - 2OP - Variable, Variable
    0x61 => %Opcode{func: &op_je/2, indirect?: false, branch?: true},
    0x62 => %Opcode{func: &op_jl/2, indirect?: false, branch?: true},
    0x63 => %Opcode{func: &op_jg/2, indirect?: false, branch?: true},
    0x74 => %Opcode{func: &op_add/2, indirect?: false, branch?: false},
    0x75 => %Opcode{func: &op_sub/2, indirect?: false, branch?: false},
    0x76 => %Opcode{func: &op_mul/2, indirect?: false, branch?: false},
    0x77 => %Opcode{func: &op_div/2, indirect?: false, branch?: false},
    0x78 => %Opcode{func: &op_mod/2, indirect?: false, branch?: false},

    # Variable Form - VAR - Operand types in next byte(s)
    0xe0 => %Opcode{func: &op_call/2, indirect?: false, branch?: false},
  }

  def get(op) do
    opcode = Map.get(@opmap, op)
    %{opcode | :form => decode_form(op)}
  end

end
