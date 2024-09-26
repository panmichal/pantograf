defmodule Pantograf.Repo do
  use Ecto.Repo,
    otp_app: :pantograf,
    adapter: Ecto.Adapters.Postgres
end
