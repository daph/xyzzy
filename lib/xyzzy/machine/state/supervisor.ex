defmodule Xyzzy.Machine.State.Supervisor do
  use Supervisor

  alias Xyzzy.Machine.State

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :state_supervisor)
  end

  def start_game(story, name) do
    Supervisor.start_child(:state_supervisor, [{story, name}])
  end

  def init(_) do
    children = [
      worker(State.Server, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
