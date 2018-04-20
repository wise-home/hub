defmodule Hub.Subscriber do
  @moduledoc """
  State for a single subscriber
  """

  @type t :: %__MODULE__{}

  defstruct channel: nil,
            pid: nil,
            pattern: nil,
            count: nil,
            multi: nil,
            ref: nil

  def new(channel, pid, pattern, count, multi) do
    ref = make_ref()

    %__MODULE__{
      channel: channel,
      pid: pid,
      pattern: pattern,
      count: count,
      multi: multi,
      ref: ref
    }
  end
end
