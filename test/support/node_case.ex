defmodule Ratelab.NodeCase do
  @timeout 10000
  defmacro __using__(opts \\ []) do
    quote do
      use ExUnit.Case, async: unquote(Keyword.get(opts, :async, true))
      import unquote(__MODULE__)

      @timeout unquote(@timeout)
    end
  end

  # This has to live in a compiled module or you'll have undefined function errors on remote nodes
  def attempt_at(node, identifier, delay, options) do
    call_node(node, fn ->
      Ratelab.LimiterSupervisor.attempt(
        identifier,
        fn _context ->
          GenServer.call(Ratelab.TheService, {:request, delay})
        end,
        options
      )
    end)
  end

  defp call_node(node, func) do
    parent = self()
    ref = make_ref()

    pid =
      Node.spawn_link(node, fn ->
        result = func.()
        send(parent, {ref, result})
        ref = Process.monitor(parent)

        receive do
          {:DOWN, ^ref, :process, _, _} -> :ok
        end
      end)

    receive do
      {^ref, result} -> {pid, result}
    after
      @timeout -> {pid, {:error, :timeout}}
    end
  end
end
