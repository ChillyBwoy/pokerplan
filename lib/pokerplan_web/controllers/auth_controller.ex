defmodule PokerplanWeb.AuthController do
  use PokerplanWeb, :controller
  alias Pokerplan.Auth.Token, as: Token

  alias Pokerplan.Auth.User

  plug Ueberauth

  defp user_attrs_from_oauth(%{info: %{nickname: nickname, image: image}, provider: :github}) do
    {:ok, %User{username: nickname, avatar_url: image}}
  end

  def callback(conn = %{assigns: %{ueberauth_failure: _}}, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: "/")
  end

  def callback(conn = %{assigns: %{ueberauth_auth: auth}}, _params) do
    with {:ok, user} <- user_attrs_from_oauth(auth) do
      conn
      |> put_session(:user_token, Token.sign(user))
      |> put_flash(:info, "Welcome, #{user.username}!")
      |> redirect(to: "/")
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: "/")
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end
end
