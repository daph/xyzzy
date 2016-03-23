defmodule Xyzzy.Machine.StateServer do
  use GenServer

  ### Public Api ###

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def pop_stack(pid) do
    GenServer.call(pid, :pop_stack)
  end

  def top_stack(pid) do
    GenServer.call(pid, :top_stack)
  end

  def push_stack(pid, value) do
    GenServer.call(pid, {:push_stack, value})
  end

  def clear_stack(pid) do
    GenServer.call(pid, :clear_stack)
  end

  def push_call_stack(pid, ret) do
    GenServer.call(pid, {:push_call_stack, ret})
  end

  def set_locals(pid, value) do
    GenServer.call(pid, {:set_locals, value})
  end

  def set_pc(pid, value) do
    GenServer.call(pid, {:set_pc, value})
  end

  def bulk_update(pid, state) do
    GenServer.call(pid, {:bulk_update, state})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  ### Private GenServer API ###

  def init(story) do
    :random.seed(:os.timestamp)
    state = Xyzzy.Machine.open_story(story)
    {:ok, state}
  end

  def handle_call(:pop_stack, _from, state = %{stack: [h|t]}) do
    {:reply, h, %{state | :stack => t}}
  end

  def handle_call(:top_stack, _from, state = %{stack: [h|_]}) do
    {:reply, h, state}
  end

  # This very well could be an async cast instead, but as this is the state
  # of a machine, we need to keep everything in step with everything else in
  # order to prevent weird race conditions.
  def handle_call({:push_stack, value}, _from, state = %{stack: stack}) do
    {:reply, :ok, %{state | :stack => [value|stack]}}
  end

  def handle_call(:clear_stack, _from, state) do
    {:reply, :ok, %{state | :stack => []}}
  end

  def handle_call({:push_call_stack, ret}, _from, state) do
    new_state =
      %{state | :call_stack => [%{:pc => state.pc,
                                  :locals => state.locals,
                                  :stack => state.stack,
                                  :ret => ret}|state.call_stack]}
    {:reply, :ok, new_state}
  end

  def handle_call({:set_locals, value}, _from, state) do
    {:reply, :ok, %{state | :locals => value}}
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
