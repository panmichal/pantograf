defmodule Pantograf.Transit do
  require Logger

  import Ecto.Query

  alias Pantograf.Transit.GTFS
  alias Pantograf.Transit.Network
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

      validated = stop_times

      # validated =
      #   Enum.reduce_while(Enum.with_index(stop_times), [], fn {stop_time, index}, insert_data ->
      #     changeset = StopTime.changeset(%StopTime{}, stop_time)

      #     if changeset.valid? do
      #       IO.inspect("Stop time #{index} valid")
      #       {:cont, insert_data ++ [stop_time]}
      #     else
      #       {:halt, {:error, changeset}}
      #     end
      #   end)

      case validated do
        {:error, changeset} ->
          {:error, changeset}

        insert_data ->
          IO.inspect("STOP TIMES VALID")

          Enum.chunk_every(insert_data, 9000)
          |> Enum.each(fn chunk ->
            IO.inspect("Insert 9000 stop times")
            repo.insert_all(StopTime, chunk)
          end)

          IO.inspect("STOP TIMES CREATED")
          {:ok, :created_stop_times}
      end
    end)
    |> Repo.transaction(timeout: :infinity)
  end

  defp update_stop_times_times(attrs) do
    [ah, am, as] = String.split(attrs[:arrival_time], ":") |> Enum.map(&String.to_integer/1)
    [dh, dm, ds] = String.split(attrs[:departure_time], ":") |> Enum.map(&String.to_integer/1)

    # ah = String.to_integer(ah)
    # dh = String.to_integer(dh)

    departure_day = div(dh, 24)

    ah = rem(ah, 24)
    dh = rem(dh, 24)

    # ah = Integer.to_string(ah) |> String.pad_leading(2, "0")
    # dh = Integer.to_string(dh) |> String.pad_leading(2, "0")

    Map.merge(attrs, %{
      arrival_time: Time.new!(ah, am, as),
      departure_time: Time.new!(dh, dm, ds),
      trip_day: departure_day
    })
  end

  defp update_stop_times_assocs(stop_times, stops, trips) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

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
  end
end
