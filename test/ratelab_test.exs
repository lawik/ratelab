defmodule RatelabTest do
  use Ratelab.NodeCase
  doctest Ratelab

  @known_slots 3
  @request_minute_limit 6
  @node1 :"node1@127.0.0.1"
  @node2 :"node2@127.0.0.1"
  @response_delay 1000
  @quick_timeout 100

  test "attempt from each node" do
    attempt = fn node ->
      attempt_at(
        node,
        "foo",
        1,
        timeout: @quick_timeout
      )
    end

    assert {_, {:ok, :response}} = attempt.(@node1)
    assert {_, {:ok, :response}} = attempt.(@node2)
  end

  test "requests beyond slot limit" do
    expect_oks =
      Enum.map(1..@known_slots, fn _ ->
        Task.async(fn ->
          attempt_at(
            @node1,
            "beyond-limit",
            @response_delay,
            timeout: @quick_timeout
          )
        end)
      end)

    :timer.sleep(300)

    expect_rate_limit =
      Task.async(fn ->
        attempt_at(
          @node2,
          "beyond-limit",
          @response_delay,
          timeout: @quick_timeout
        )
      end)

    assert {_, {:rate_limited, :concurrent_requests, {:limit, @known_slots}}} =
             Task.await(expect_rate_limit)

    Enum.each(expect_oks, fn t ->
      assert {_, {:ok, :response}} = Task.await(t)
    end)
  end

  test "requests beyond minute limit" do
    expect_oks =
      Enum.map(1..@request_minute_limit, fn _ ->
        Task.async(fn ->
          attempt_at(
            @node1,
            "minute-limit",
            # Very quick response
            1,
            timeout: 1000 * @request_minute_limit
          )
        end)
      end)

    :timer.sleep(300)

    expect_rate_limit =
      Task.async(fn ->
        attempt_at(
          @node2,
          "minute-limit",
          # Very quick response
          1,
          timeout: 10000
        )
      end)

    assert {_, {:rate_limited, :requests_over_time, {:minute, @request_minute_limit}}} =
             Task.await(expect_rate_limit)

    Enum.each(expect_oks, fn t ->
      assert {_, {:ok, :response}} = Task.await(t)
    end)
  end
end
