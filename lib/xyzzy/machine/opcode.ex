defmodule Xyzzy.Machine.Opcode do
  defstruct func: nil, # Function to execute the opcode
            form: nil, # Opcode form
            branch?: false # Does this opcode branch
end
