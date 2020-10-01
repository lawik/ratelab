defmodule Ratelab.Limiter do
  use GenServer, restart: :transient

  @default_timeout 10000
  @minute_limit 6

  def start_link(opts) do
    {args, opts} = Keyword.pop!(opts, :args)
    GenServer.start_link(__MODULE__, args, opts)
  end

  @impl GenServer
  def init(%{data: data, max_concurrency: max_concurrency}) do
    pool_config = [
      worker_module: Ratelab.Worker,
      size: max_concurrency,
      max_overflow: 0
    ]

    {:ok, pid} = :poolboy.start_link(pool_config)

    state = %{
      data: data,
      minute: get_current_minute(),
      max_concurrency: max_concurrency,
      request_count: 0,
      pool: pid
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(
        {:attempt, callback, options},
        from,
        %{pool: pool, data: data} = state
      ) do
    timeout = options[:timeout] || @default_timeout
    %{request_count: new_count} = state = count_request(state)

    if new_count > @minute_limit do
      {:reply, {:rate_limited, :requests_over_time, {:minute, @minute_limit}}, state}
    else
      # We return :noreply and use an explicit GenServer.reply to allow the limiter to move on with other work
      # while this keeps happening

      Task.start(fn ->
        try do
          :poolboy.transaction(
            pool,
            fn worker_pid ->
              wrapped_function = fn ->
                callback.(data)
              end

              result = GenServer.call(worker_pid, {:work, wrapped_function})
              GenServer.reply(from, {:ok, result})
            end,
            timeout
          )
        catch
          :exit, {:timeout, {:gen_server, :call, [_, {:checkout, _, _}, _]}} ->
            GenServer.reply(
              from,
              {:rate_limited, :concurrent_requests, {:limit, state.max_concurrency}}
            )
        end
      end)

      {:noreply, state}
    end
  end

  defp count_request(%{minute: old_minute} = state) do
    current_minute = get_current_minute()

    %{request_count: count} =
      state =
      if old_minute != current_minute do
        %{state | minute: current_minute, request_count: 0}
      else
        state
      end

    count = count + 1
    %{state | request_count: count}
  end

  defp get_current_minute do
    "Etc/UTC"
    |> DateTime.now!()
    |> DateTime.truncate(:second)
    |> Map.put(:second, 0)
    |> DateTime.to_iso8601()
  end
end
