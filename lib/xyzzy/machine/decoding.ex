defmodule Xyzzy.Machine.Decoding do
  alias Xyzzy.Machine.State
  alias Xyzzy.Machine.Opcodes
  alias Xyzzy.Machine.OpInfo

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

  def unpack!(address, version) do
    {:ok, addr} = unpack(address, version)
    addr
  end

  def get_opcode(game_name) do
    state = State.Server.get_state(game_name)
    opcode =
      state.memory
      |> :binary.at(state.pc)
      |> Opcodes.get

    opinfo =
      case opcode.form do
        {_, [:nb]} ->
          state.memory
          |> :binary.at(state.pc+1)
          |> decode_nb
          |> get_op_info(opcode, state.pc+1, game_name)
        {_, f} ->
          get_op_info(f, opcode, state.pc, game_name)
      end

    {opcode, opinfo}
  end

  defp get_oplen(op_types) do
    Enum.reduce(op_types, 0, fn(x, acc) ->
      acc + Map.fetch!(@operand_sizes, x)
    end)
  end

  # Gets all the info needed for a good, strong opcode to run.
  defp get_op_info(op_types, opcode, start_addr, game_name) do
    state = State.Server.get_state(game_name)
    end_addr = get_end_address(op_types, start_addr)
    raw_operands = get_raw_operands(op_types, state.memory, start_addr)

    operands =
      if opcode.indirect? do
        raw_operands
      else
        get_operands(op_types, raw_operands, game_name)
      end
      partial_info =
        %OpInfo{:operands => operands,
                :operand_types => op_types}

      if opcode.branch? do
        {branch_cond, branch_addr, npc} = get_branch_info(end_addr, state.memory)
        %{partial_info | :branch_addr => branch_addr,
                         :branch_cond => branch_cond,
                         :next_pc => npc}
      else
        %{partial_info | :return_store => :binary.at(state.memory, end_addr),
                         :next_pc => end_addr+1}
      end
  end

  defp get_branch_info(end_addr, mem) do
    label = :binary.at(mem, end_addr) |> :binary.encode_unsigned
    # First bit (tf), is if we jump if true (1) or false (0)
    # Second bit (l), is if the offset is one byte (1) or two (0)
    # rest is the offset (or first half if `l` is unset)
    << tf :: 1, l :: 1, rest :: 6 >> = label

    {offset, npc} =
      case l do
        1 ->
          {rest, end_addr+1}
        0 ->
          {rest + :binary.at(mem, end_addr+1), end_addr+2}
      end

    branch_cond =
      case tf do
        1 -> true
        0 -> false
      end

    {branch_cond, offset+npc-2, npc}
  end

  # Gets the address after all the operands. This is sometimes the variable to
  # Store the return value, or just the next opcode.
  defp get_end_address(op_types, start_addr) do
    len = get_oplen(op_types)
    start_addr+len+1
  end

  def get_operands(op_types, raw_operands, game_name) do
    case :v in op_types do
      true -> get_operands(op_types, raw_operands, [], game_name)
              |> Enum.reverse
      false -> raw_operands
    end
  end

  def get_operands([], [], acc, _game_name), do: acc
  def get_operands(_op_types, [], acc, _game_name), do: acc
  def get_operands([], _raw_operands, acc, _game_name), do: acc
  def get_operands([type|tt], [op|ot], acc, game_name) when type != :v do
    get_operands(tt, ot, [op|acc], game_name)
  end
  def get_operands([_|tt], [op|ot], acc, game_name) when op == 0x00 do
    val = State.Server.pop_stack(game_name)
    get_operands(tt, ot, [val|acc], game_name)
  end
  def get_operands([_|tt], [op|ot], acc, game_name) when op in 0x01..0x0f do
    val = State.Server.get_local(game_name, op)
    get_operands(tt, ot, [val|acc], game_name)
  end
  def get_operands([_|tt], [op|ot], acc, game_name) when op in 0x10..0xff do
    val = State.Server.get_global(game_name, op)
    get_operands(tt, ot, [val|acc], game_name)
  end

  # TODO: Dedup the work get_operands does by using read_variable
  def read_variable(var, game_name, opts \\ [indirect: false])
  def read_variable(var, game_name, opts) when var == 0x00 do
    unless opts[:indirect] do
      State.Server.pop_stack(game_name)
    else
      State.Server.top_stack(game_name)
    end
  end
  def read_variable(var, game_name, _opts) when var in 0x01..0x0f do
    State.Server.get_local(game_name, var)
  end
  def read_varialbe(var, game_name, _opts) when var in 0x10..0xff do
    State.Server.get_global(game_name, var)
  end

  def decode_form(op) when op in 0x00..0x1f, do: {:op2, [:sc, :sc]}
  def decode_form(op) when op in 0x20..0x3f, do: {:op2, [:sc, :v]}
  def decode_form(op) when op in 0x40..0x5f, do: {:op2, [:v, :sc]}
  def decode_form(op) when op in 0x60..0x7f, do: {:op2, [:v, :v]}
  def decode_form(op) when op in 0x80..0x8f, do: {:op1, [:lc]}
  def decode_form(op) when op in 0x90..0x9f, do: {:op1, [:sc]}
  def decode_form(op) when op in 0xa0..0xaf, do: {:op1, [:v]}
  def decode_form(op) when op == 0xbe, do: {:ext, [:nb]}
  def decode_form(op) when op in 0xb0..0xbf, do: {:op1, [:o]}
  def decode_form(op) when op in 0xc0..0xdf, do: {:op2, [:nb]}
  def decode_form(op) when op in 0xe0..0xff, do: {:var, [:nb]}

  defp get_raw_operands(op_types, mem, start_addr) when not is_list(start_addr) do
    len = get_oplen(op_types)
    mem
    |> :binary.part({start_addr+1, len})
    |> get_raw_operands(op_types, [])
    |> Enum.reverse
  end

  defp get_raw_operands(_, [], acc), do: acc
  defp get_raw_operands(_, [:o|_], acc), do: acc
  defp get_raw_operands(<<>>, _, acc), do: acc
  defp get_raw_operands(bin, [h|t], acc) do
    s = Map.fetch!(@operand_sizes, h) * 8
    << x :: size(s), rest :: binary >> = bin
    get_raw_operands(rest, t, [x|acc])
  end

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

  def decode_routine_locals(routine, %State{memory: mem, version: ver})
  when ver in 1..4 do
    local_num = :binary.at(mem, routine)
    locals = :binary.part(mem, {routine+1, 2*local_num})
    for << x :: 16 <- locals >>, do: x
  end

  def write_variable(var, val, game_name, opts \\ [indirect: false])
  def write_variable(var, val, game_name, opts) when var == 0x00 do
    unless opts[:indirect] do
      State.Server.push_stack(game_name, val)
    else
      State.Server.set_top_stack(game_name, val)
    end
  end
  def write_variable(var, val, game_name, _opts) when var in 0x01..0x0f do
    State.Server.set_local(game_name, var, val)
  end
  def write_variable(var, val, game_name, _opts) when var in 0x10..0xff do
    State.Server.set_global(game_name, var, val)
  end

  # Only make signed if the num is large enough to have
  # the sign bit flipped (>255). 2 bytes/16 bits.
  # If we get a num larger than 65535, something has gone
  # wrong and we should crash.
  def make_signed(num) when num > 255 and num < 65536 do
    bin_num = :binary.encode_unsigned(num)
    << x :: 1, _ :: bitstring >> = bin_num
    if x == 1 do
      65536 - num
    else
      num
    end
  end
  def make_signed(num) when num <= 255, do: num

end
