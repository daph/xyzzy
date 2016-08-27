defmodule Xyzzy.Machine.State do
  defstruct version: 0,
            release: 0,
            pc: 0,
            stack: [],
            call_stack: [],
            locals: %{},
            memory: 0,
            static_mem: 0,
            high_mem: 0,
            dictionary: 0,
            object_table: 0,
            abbr_table: 0,
            global_vars: 0,
            flags1: 0,
            flags2: 0
end
