defmodule Pantograf.Transit.Route do
  use Pantograf.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @derive {Jason.Encoder, only: [:id, :short_name, :long_name, :type, :custom_type]}
  schema "transit_routes" do
    field :identifier, :string
    field :short_name, :string
    field :long_name, :string
    field :description, :string
    field :type, :integer
    field :custom_type, :string

    belongs_to :network, Pantograf.Transit.Network
    has_many :trips, Pantograf.Transit.Trip

    timestamps(inserted_at: :created_at, updated_at: :updated_at)
  end

  def changeset(route, attrs) do
    route
    |> cast(attrs, [
      :identifier,
      :short_name,
      :long_name,
      :description,
      :type,
      :custom_type,
      :network_id
    ])
    |> validate_required([:identifier, :short_name, :description, :type])
  end
end
