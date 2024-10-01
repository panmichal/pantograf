defmodule Pantograf.Transit.Shape do
  use Pantograf.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "transit_shapes" do
    field :identifier, :string
    field :points, Geo.PostGIS.Geometry

    belongs_to :network, Pantograf.Transit.Network
    has_many :trips, Pantograf.Transit.Trip
    has_many :routes, through: [:trips, :route]

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(shape, attrs) do
    shape
    |> cast(attrs, [:identifier, :points, :network_id])
    |> validate_required([:identifier, :points])
  end
end
