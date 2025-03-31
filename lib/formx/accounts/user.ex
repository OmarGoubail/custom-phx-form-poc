defmodule Formx.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :nickname, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :nickname])
    |> validate_required([:name, :nickname])
    |> validate_length(:name, min: 5, max: 50, message: "Name must be between 5 and 50 characters")
  end
end
