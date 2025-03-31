defmodule Formx.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Formx.Accounts` context.
  """

  @doc """
  Generate a user.
  """
  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        name: "some name",
        nickname: "some nickname"
      })
      |> Formx.Accounts.create_user()

    user
  end
end
