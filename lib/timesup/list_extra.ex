defmodule Timesup.ListExtra do
  @doc """
  Pads two list so that they are the same length by repeating the shortest list

  ## Examples

    iex> Timesup.ListExtra.pad([1, 2], [3, 4])
    {[1, 2], [3, 4]}

    iex> Timesup.ListExtra.pad([1, 2], [3, 4, 5])
    {[1, 2, 1], [3, 4, 5]}

    iex> Timesup.ListExtra.pad([1, 2, 3], [4, 5])
    {[1, 2, 3], [4, 5, 4]}

    iex> Timesup.ListExtra.pad([], [4, 5])
    {[], [4, 5]}
  """
  def pad(l1, l2) when length(l1) == length(l2), do: {l1, l2}

  def pad(l1, l2) when length(l1) < length(l2) do
    {do_pad(l1, l2), l2}
  end

  def pad(l1, l2) when length(l1) > length(l2) do
    {l1, do_pad(l2, l1)}
  end

  defp do_pad([], _), do: []
  defp do_pad(l1, l2), do: do_pad(l1, l2, l1)
  defp do_pad(_, [], _), do: []
  defp do_pad([], [_ | _] = l2, original_l1), do: do_pad(original_l1, l2)

  defp do_pad([head | tail_1], [_ | tail_2], original_l1) do
    [head | do_pad(tail_1, tail_2, original_l1)]
  end
end
