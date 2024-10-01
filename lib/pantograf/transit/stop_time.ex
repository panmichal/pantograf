defmodule Pantograf.Transit.StopTime do
  use Pantograf.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "transit_stop_times" do
    field :arrival_time, :time
    field :departure_time, :time
    field :trip_day, :integer

    belongs_to :trip, Pantograf.Transit.Trip
    belongs_to :stop, Pantograf.Transit.Stop
  end

  def changeset(stop_time, attrs) do
    attrs = update_times(attrs)

    stop_time
    |> cast(attrs, [:arrival_time, :departure_time, :trip_day])
    |> validate_required([:arrival_time, :departure_time, :trip_day])
  end

  defp update_times(attrs) do
    [ah, am, as] = String.split(attrs[:arrival_time], ":")
    [dh, dm, ds] = String.split(attrs[:departure_time], ":")

    ah = String.to_integer(ah)
    dh = String.to_integer(dh)

    departure_day = div(dh, 24)

    ah = rem(ah, 24)
    dh = rem(dh, 24)

    ah = Integer.to_string(ah) |> String.pad_leading(2, "0")
    dh = Integer.to_string(dh) |> String.pad_leading(2, "0")

    Map.merge(attrs, %{
      arrival_time: Enum.join([ah, am, as], ":"),
      departure_time: Enum.join([dh, dm, ds], ":"),
      trip_day: departure_day
    })
  end
end
