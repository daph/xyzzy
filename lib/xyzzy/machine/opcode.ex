defmodule Xyzzy.Machine.Opcode do
  defstruct func: nil, # Function to execute the opcode
            form: nil, # Opcode form
            indirect?: false, # Indirect refernce to variables/stack pointer
            branch?: false # Does this opcode branch
end
