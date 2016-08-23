defmodule Xyzzy.Machine.State.Server do
  use GenServer

  alias Xyzzy.Machine.State

  ### Public Api ###

  def start_link({story, name}) do
    GenServer.start_link(__MODULE__, story, name: via_tuple(name))
  end

  def via_tuple(game_name) do
    {:via, State.Registry, game_name}
  end

  def pop_stack(game_name) do
    GenServer.call(via_tuple(game_name), :pop_stack)
  end

  def top_stack(game_name) do
    GenServer.call(via_tuple(game_name), :top_stack)
  end

  def set_top_stack(game_name, value) do
    GenServer.call(via_tuple(game_name), {:set_top_stack, value})
  end

  def push_stack(game_name, value) do
    GenServer.call(via_tuple(game_name), {:push_stack, value})
  end

  def clear_stack(game_name) do
    GenServer.call(via_tuple(game_name), :clear_stack)
  end

  def push_call_stack(game_name, pc, return_store) do
    GenServer.call(via_tuple(game_name), {:push_call_stack, pc, return_store})
  end

  def get_local(game_name, l) do
    GenServer.call(via_tuple(game_name), {:get_local, l})
  end

  def set_local(game_name, l, value) do
    GenServer.call(via_tuple(game_name), {:set_local, l, value})
  end

  def set_locals(game_name, value) do
    GenServer.call(via_tuple(game_name), {:set_locals, value})
  end

  def get_global(game_name, g) do
    GenServer.call(via_tuple(game_name), {:get_global, g})
  end

  def set_global(game_name, g, value) do
    GenServer.call(via_tuple(game_name), {:set_global, g, value})
  end

  def set_pc(game_name, value) do
    GenServer.call(via_tuple(game_name), {:set_pc, value})
  end

  def bulk_update(game_name, state) do
    GenServer.call(via_tuple(game_name), {:bulk_update, state})
  end

  def get_state(game_name) do
    GenServer.call(via_tuple(game_name), :get_state)
  end

  ### Private GenServer API ###

  def init(story) do
    :rand.seed(:exsplus, :os.timestamp)
    state = Xyzzy.Machine.open_story(story)
    {:ok, state}
  end

  def handle_call(:pop_stack, _from, state = %State{stack: [h|t]}) do
    {:reply, h, %{state | :stack => t}}
  end

  def handle_call(:top_stack, _from, state = %State{stack: [h|_]}) do
    {:reply, h, state}
  end

  def handle_call({:set_top_stack, value}, _from, state = %State{stack: [_|rest]}) do
    {:replay, :ok, %{state | :stack => [value|rest]}}
  end

  # This very well could be an async cast instead, but as this is the state
  # of a machine, we need to keep everything in step with everything else in
  # order to prevent weird race conditions.
  def handle_call({:push_stack, value}, _from, state = %State{stack: stack}) do
    {:reply, :ok, %{state | :stack => [value|stack]}}
  end

  def handle_call(:clear_stack, _from, state) do
    {:reply, :ok, %{state | :stack => []}}
  end

  def handle_call({:push_call_stack, pc, return_store}, _from, state) do
    new_state =
      %{state | :call_stack => [%{:pc => pc,
                                  :locals => state.locals,
                                  :stack => state.stack,
                                  :return_store => return_store}|state.call_stack]}
    {:reply, :ok, new_state}
  end

  def handle_call({:get_local, l}, _from, state = %State{locals: locals}) do
    case Map.get(locals, l) do
      nil -> {:stop, "Local #{l} does not exist!"}
      local -> {:reply, local, state}
    end
  end

  def handle_call({:set_local, l, value}, _from, state = %State{locals: locals}) do
      new_locals = %{locals | l => value}
      {:reply, :ok, %{state | :locals => new_locals}}
  end

  def handle_call({:set_locals, value}, _from, state) do
    {:reply, :ok, %{state | :locals => value}}
  end

  def handle_call({:get_global, g}, _from, state = %State{global_vars: gv}) do
    case Map.get(gv, g) do
      nil -> {:stop, "Global #{g} does not exist!"}
      global -> {:reply, global, state}
    end
  end

  def handle_call({:set_global, g, value}, _from, state = %State{global_vars: gv}) do
    new_globals = %{gv | g => value}
    {:reply, :ok, %{state | :global_vars => new_globals}}
  end

  def handle_call({:set_pc, value}, _from, state) do
    {:reply, :ok, %{state | :pc => value}}
  end

  def handle_call({:bulk_update, new_state}, _from, state) do
    final_state = Map.merge(state, new_state)
    {:reply, :ok, final_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
