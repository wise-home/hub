defmodule Hub.Subscriber do
  @moduledoc """
  State for a single subscriber
  """

  @type t :: %__MODULE__{}

  defstruct [
    :channel_name,
    :pid,
    :pattern,
    :count,
    :multi,
    :ref
  ]

  def new(channel_name, pid, pattern, count, multi) do
    ref = make_ref()

    %__MODULE__{
      channel_name: channel_name,
      pid: pid,
      pattern: pattern,
      count: count,
      multi: multi,
      ref: ref
    }
  end
end
