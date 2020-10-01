defmodule Ratelab.LimiterSupervisor do
  use DynamicSupervisor

  @max_concurrency 3

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_limiter(identifier) do
    name = get_name(identifier)

    spec =
      {Ratelab.Limiter,
       args: %{
         data: identifier,
         max_concurrency: @max_concurrency
       },
       name: {:global, name},
       restart: :transient}

    # This locks the name until starting has been figured out, a global transaction across the cluster
    :global.trans({__MODULE__, name}, fn ->
      case DynamicSupervisor.start_child(__MODULE__, spec) do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, pid}} -> {:ok, pid}
        error -> error
      end
    end)
  end

  def attempt(identifier, callback, options) do
    name = get_name(identifier)

    case :global.whereis_name(name) do
      :undefined ->
        {:ok, pid} = start_limiter(identifier)
        GenServer.call(pid, {:attempt, callback, options}, :infinity)

      pid when is_pid(pid) ->
        GenServer.call(pid, {:attempt, callback, options}, :infinity)
    end
  end

  defp get_name(identifier) do
    {:limiter, identifier}
  end
end
