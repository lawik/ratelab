defmodule Ratelab.Limiter do
  use GenServer, restart: :transient

  @default_timeout 10000

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
      request_count: 0,
      pool: pid
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:attempt, callback, options}, from, %{pool: pool, data: data} = state) do
    timeout = options[:timeout] || @default_timeout

    # We return :noreply and use an explicit GenServer.reply to allow the limiter to move on
    Task.start(fn ->
      case :poolboy.checkout(pool, false, timeout) do
        :full ->
          GenServer.reply(from, {:rate_limited, :no_slots_available})

        worker_pid ->
          wrapped_function = fn ->
            callback.(data)
          end

          result = GenServer.call(worker_pid, {:work, wrapped_function})
          :poolboy.checkin(pool, worker_pid)
          GenServer.reply(from, {:ok, result})
      end
    end)

    {:noreply, state}
  end
end
