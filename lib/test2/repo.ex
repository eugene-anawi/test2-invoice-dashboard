defmodule Test2.Repo do
  use Ecto.Repo,
    otp_app: :test2,
    adapter: Ecto.Adapters.Postgres
end