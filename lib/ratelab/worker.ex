defmodule Ratelab.Worker do
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl GenServer
  def init(_args) do
    {:ok, nil}
  end

  @impl GenServer
  def handle_call({:work, function}, _from, state) do
    result = function.()
    {:reply, result, state}
  end
end
