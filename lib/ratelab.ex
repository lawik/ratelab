defmodule Ratelab do
  @moduledoc """
  # Examples
  iex> {:ok, :response} = Ratelab.attempt("my-org-1", fn _context -> :response end, timeout: 1000)
  """

  defdelegate attempt(identifier, callback, options), to: Ratelab.LimiterSupervisor
end
