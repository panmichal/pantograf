defmodule Pantograf.Transit do
  require Logger

  import Ecto.Query

  alias Pantograf.Transit.GTFS
  alias Pantograf.Transit.Network
  alias Pantograf.Transit.Route
  alias Pantograf.Transit.Shape
  alias Pantograf.Transit.Stop
  alias Pantograf.Transit.StopTime
  alias Pantograf.Transit.Trip
  alias Pantograf.Repo

  def get_network_by_location(location, preloads \\ []) do
    Network
    |> Repo.get_by(location: location)
    |> Repo.preload(preloads)
  end

  def create_network(location, stops, stop_times, shapes, routes, trips) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :network,
      Network.changeset(%Network{}, %{
        location: location,
        stops: stops,
        shapes: shapes,
        routes: routes
      })
    )
    |> Ecto.Multi.run(:trips, fn repo, %{network: network} ->
      trips = update_trip_assocs(trips, network.shapes, network.routes)

      validated =
        Enum.reduce_while(trips, [], fn trip, insert_data ->
          changeset = Trip.changeset(%Trip{}, trip)

          if changeset.valid? do
            {:cont, insert_data ++ [trip]}
          else
            {:halt, {:error, changeset}}
          end
        end)

      case validated do
        {:error, changeset} ->
          {:error, changeset}

        insert_data ->
          inserted =
            Enum.chunk_every(insert_data, 9000)
            |> Enum.flat_map(fn chunk ->
              {_, inserted} = repo.insert_all(Trip, chunk, returning: true)

              inserted
            end)
            |> Enum.map(fn inserted_trip ->
              {inserted_trip.identifier, inserted_trip}
            end)
            |> Map.new()

          {:ok, inserted}
      end
    end)
    |> Ecto.Multi.run(:stop_times, fn repo, %{network: network, trips: trips} ->
      stop_times = update_stop_times_assocs(stop_times, network.stops, trips)

      Enum.chunk_every(stop_times, 9000)
      |> Enum.each(fn chunk ->
        IO.inspect("Insert 9000 stop times")
        repo.insert_all(StopTime, chunk)
      end)

      {:ok, :created_stop_times}
    end)
    |> Repo.transaction(timeout: :infinity)
  end

  defp update_stop_times_times(attrs) do
    [ah, am, as] = String.split(attrs[:arrival_time], ":") |> Enum.map(&String.to_integer/1)
    [dh, dm, ds] = String.split(attrs[:departure_time], ":") |> Enum.map(&String.to_integer/1)

    departure_day = div(dh, 24)

    ah = rem(ah, 24)
    dh = rem(dh, 24)

    Map.merge(attrs, %{
      arrival_time: Time.new!(ah, am, as),
      departure_time: Time.new!(dh, dm, ds),
      trip_day: departure_day
    })
  end

  defp update_stop_times_assocs(stop_times, stops, trips) do
    Enum.map(stop_times, fn stop_time ->
      stop_id = stop_time.stop_id
      stop = Enum.find(stops, fn stop -> stop.identifier == stop_id end) |> Map.from_struct()
      trip_id = stop_time.trip_id
      trip = Map.get(trips, trip_id)

      Map.put(stop_time, :stop_id, stop.id)
      |> Map.put(:trip_id, trip.id)
      # |> Map.put(:created_at, now)
      # |> Map.put(:updated_at, now)
      |> update_stop_times_times()
    end)
  end

  defp update_trip_assocs(trips, shapes, routes) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.map(trips, fn trip ->
      shape_id = trip.shape_id
      shape = Enum.find(shapes, fn shape -> shape.identifier == shape_id end) |> Map.from_struct()

      route_id = trip.route_id
      route = Enum.find(routes, fn route -> route.identifier == route_id end) |> Map.from_struct()

      Map.put(trip, :shape_id, shape.id)
      |> Map.put(:route_id, route.id)
      |> Map.put(:created_at, now)
      |> Map.put(:updated_at, now)
    end)
  end

  def store_network_data(network_location, gtfs_path) do
    gtfs_streams = GTFS.load_gtfs(gtfs_path)

    gtfs = GTFS.parse_gtfs(gtfs_streams)

    case get_network_by_location(network_location) do
      nil ->
        Logger.info("Create transit network for #{network_location}")

        create_network(
          network_location,
          gtfs.stops,
          gtfs.stop_times,
          gtfs.shapes,
          gtfs.routes,
          gtfs.trips
        )

      network ->
        Logger.info("Update transit network for #{network_location}")

        network
        |> Network.changeset(%{stops: gtfs.stops})
        |> Repo.update()
    end
  end

  def get_stops_by_location(location) do
    query = from(s in Stop, join: n in assoc(s, :network), where: n.location == ^location)

    Repo.all(query)
  end

  def get_nearby_stops(lat, lon, radius, network) do
    from = %Geo.Point{coordinates: {lon, lat}, srid: 4326}

    query =
      from s in Stop,
        join: n in assoc(s, :network),
        where: n.id == ^network.id,
        where:
          fragment(
            "ST_DWithin(?::geography, ?::geography, ?)",
            s.coordinates,
            ^from,
            ^radius
          )

    Repo.all(query)
  end

  @doc """
   Returns all shapes that pass through the given stops.
  """
  def get_shapes_for_stops(stops) do
    stop_ids = Enum.map(stops, & &1.id)

    query =
      from sh in Shape,
        distinct: sh.id,
        join: t in assoc(sh, :trips),
        join: s in assoc(t, :stops),
        preload: [:routes],
        where: s.id in ^stop_ids

    Repo.all(query)
  end

  @doc """
  Returns all unique routes the given shapes are associated with.
  Naive implementation for now.
  """
  @spec get_routes_for_shapes([Shape.t()]) :: [Route.t()]
  def get_routes_for_shapes(shapes) do
    shapes
    |> Enum.flat_map(& &1.routes)
    |> Enum.uniq_by(& &1.id)
  end

  @doc """
  Groups trips by type and by custom type within each type group.
  Sorts the top-level groups by type.
  """
  @spec group_routes([Route.t()]) :: map()
  def group_routes(routes) do
    Enum.group_by(routes, &{&1.type, &1.custom_type})
    |> Enum.group_by(fn {{type, _}, _} -> type end, fn {{_, custom_type}, routes} ->
      {custom_type, routes}
    end)
    |> Enum.sort_by(fn {type, _} -> type end)
    |> Enum.into(%{})
  end
end
