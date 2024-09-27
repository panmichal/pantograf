defmodule Pantograf.Transit.GTFS do
  require CSV

  alias Pantograf.Transit.RouteType

  @route_types %{
    0 => "Tram, Streetcar, Light rail",
    1 => "Subway, Metro",
    2 => "Rail",
    3 => "Bus",
    4 => "Ferry",
    5 => "Cable tram",
    6 => "Aerial lift",
    7 => "Funicular",
    11 => "Trolleybus",
    12 => "Monorail"
  }

  def get_route_types() do
    @route_types
  end

  def load_gtfs(dir_path) do
    stops = File.stream!(dir_path <> "/stops.txt", [:trim_bom])
    stop_times = File.stream!(dir_path <> "/stop_times.txt", [:trim_bom])
    shapes = File.stream!(dir_path <> "/shapes.txt", [:trim_bom])
    routes = File.stream!(dir_path <> "/routes.txt", [:trim_bom])
    trips = File.stream!(dir_path <> "/trips.txt", [:trim_bom])
    route_types = File.stream!(dir_path <> "/route_types.txt", [:trim_bom])

    %{
      stops_stream: stops,
      stop_times_stream: stop_times,
      routes_stream: routes,
      route_types_stream: route_types,
      shapes_stream: shapes,
      trips_stream: trips
    }
  end

  def parse_gtfs(gtfs_streams) do
    stops = parse_stops(gtfs_streams.stops_stream)
    stop_times = parse_stop_times(gtfs_streams.stop_times_stream)
    route_types = parse_route_types(gtfs_streams.route_types_stream)
    routes = parse_routes(gtfs_streams.routes_stream) |> replace_route_types(route_types)
    shapes = parse_shapes(gtfs_streams.shapes_stream)
    trips = parse_trips(gtfs_streams.trips_stream)

    %{
      stops: stops,
      stop_times: stop_times,
      routes: routes,
      route_types: route_types,
      shapes: shapes,
      trips: trips
    }
  end

  def parse_trips(csv) do
    rows = CSV.decode!(csv, headers: true)

    Enum.map(rows, fn row ->
      %{
        identifier: row["trip_id"],
        route_id: row["route_id"],
        shape_id: row["shape_id"],
        headsign: row["trip_headsign"]
      }
    end)
  end

  def parse_stop_times(csv) do
    rows = CSV.decode!(csv, headers: true)

    Enum.map(rows, fn row ->
      %{
        stop_id: row["stop_id"],
        trip_id: row["trip_id"],
        arrival_time: row["arrival_time"],
        departure_time: row["departure_time"]
      }
    end)
  end

  def parse_stops(csv) do
    rows = CSV.decode!(csv, headers: true)

    Enum.map(rows, fn row ->
      {lon, _} = row["stop_lon"] |> Float.parse()
      {lat, _} = row["stop_lat"] |> Float.parse()

      %{
        identifier: row["stop_id"],
        name: row["stop_name"],
        code: row["stop_code"],
        coordinates: %Geo.Point{coordinates: {lon, lat}, srid: 4326}
      }
    end)
  end

  def parse_route_types(csv) do
    rows = CSV.decode!(csv, headers: true)

    Enum.map(rows, fn row ->
      %RouteType{
        id: row["route_type2_id"],
        name: row["route_type2_name"]
      }
    end)
  end

  def parse_routes(csv) do
    rows = CSV.decode!(csv, headers: true)

    Enum.map(rows, fn row ->
      %{
        identifier: row["route_id"],
        short_name: row["route_short_name"],
        long_name: row["route_long_name"],
        description: row["route_desc"],
        type: row["route_type"],
        custom_type: row["route_type2_id"]
      }
    end)
  end

  def parse_shapes(csv) do
    rows = CSV.decode!(csv, headers: true)

    rows
    |> Enum.group_by(fn row -> row["shape_id"] end)
    |> Enum.map(fn {shape_id, rows} ->
      point_coordinates =
        rows
        |> Enum.sort_by(fn row -> row["shape_pt_sequence"] |> String.to_integer() end)
        |> Enum.map(fn row ->
          lon = row["shape_pt_lon"] |> String.to_float()
          lat = row["shape_pt_lat"] |> String.to_float()

          {lon, lat}
        end)

      %{identifier: shape_id, points: %Geo.LineString{coordinates: point_coordinates, srid: 4326}}
    end)
  end

  def stops_to_features(stops) do
    features =
      Enum.map(stops, fn stop ->
        %{
          "type" => "Feature",
          "geometry" => %{
            "type" => "Point",
            "coordinates" => Tuple.to_list(stop.coordinates.coordinates)
          },
          "properties" => %{
            "name" => stop.name,
            "id" => stop.id
          }
        }
      end)

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  def shapes_to_features(shapes) do
    features =
      Enum.map(shapes, fn shape ->
        routes = Enum.map(shape.routes, fn route -> route.id end)

        coordinates =
          Enum.map(shape.points.coordinates, fn linestring_point ->
            Tuple.to_list(linestring_point)
          end)

        %{
          "type" => "Feature",
          "properties" => %{"id" => shape.id, "routes" => routes},
          "geometry" => %{
            "type" => "LineString",
            "coordinates" => coordinates
          }
        }
      end)

    %{
      "type" => "FeatureCollection",
      "features" => features
    }
  end

  defp replace_route_types(routes, route_types) do
    Enum.map(routes, fn route ->
      route_type = Enum.find(route_types, fn rt -> rt.id == route.custom_type end)

      %{route | custom_type: route_type.name}
    end)
  end
end
