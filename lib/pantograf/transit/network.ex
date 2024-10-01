defmodule Pantograf.Transit.Network do
  use Pantograf.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "transit_networks" do
    field :location, :string

    has_many :stops, Pantograf.Transit.Stop
    has_many :shapes, Pantograf.Transit.Shape
    has_many :routes, Pantograf.Transit.Route

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(network, attrs) do
    network
    |> cast(attrs, [:location])
    |> cast_assoc(:stops)
    |> cast_assoc(:shapes)
    |> cast_assoc(:routes)
    |> validate_required([:location])
  end
end
