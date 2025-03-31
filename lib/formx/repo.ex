defmodule Formx.Repo do
  use Ecto.Repo,
    otp_app: :formx,
    adapter: Ecto.Adapters.SQLite3
end
