defmodule Ratelab do
  @moduledoc """
  # Examples
  iex> {:ok, :response} = Ratelab.attempt("my-org-1", fn _context -> :response end, timeout: 1000)
  """

  def attempt(identifier, callback, options),
    do: Ratelab.LimiterSupervisor.attempt(identifier, callback, options)
end
