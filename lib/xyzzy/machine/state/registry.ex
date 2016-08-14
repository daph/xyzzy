defmodule Xyzzy.Machine.State.Registry do
  use GenServer

  # API

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: :state_registry)
  end

  def whereis_name(game_name) do
    GenServer.call(:state_registry, {:whereis_name, game_name})
  end

  def register_name(game_name, pid) do
    GenServer.call(:state_registry, {:register_name, game_name, pid})
  end

  def unregister_name(game_name) do
    GenServer.cast(:state_registry, {:unregister_name, game_name})
  end

  def send(game_name, message) do
    case whereis_name(game_name) do
      :undefined ->
        {:badarg, {game_name, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  # SERVER

  def init(_) do
    {:ok, Map.new}
  end

  def handle_call({:whereis_name, game_name}, _from, state) do
    {:reply, Map.get(state, game_name, :undefined), state}
  end

  def handle_call({:register_name, game_name, pid}, _from, state) do
    case Map.get(state, game_name) do
      nil ->
        Process.monitor(pid)
        {:reply, :yes, Map.put(state, game_name, pid)}

      _ ->
        {:reply, :no, state}
    end
  end

  def handle_cast({:unregister_name, game_name}, state) do
    {:noreply, Map.delete(state, game_name)}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, remove_pid(state, pid)}
  end

  def remove_pid(state, pid_to_remove) do
    remove = fn {_key, pid} -> pid != pid_to_remove end
    Enum.filter(state, remove) |> Enum.into(%{})
  end
end
