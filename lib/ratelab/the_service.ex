defmodule Ratelab.TheService do
  use GenServer

  def start_link(nil) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_args) do
    {:ok, nil}
  end

  def handle_call({:request, slowness}, _from, state) do
    :timer.sleep(slowness)
    {:reply, :response, state}
  end
end
