defmodule Pokerplan.Auth.Token do
  @max_age 60 * 60 * 24 * 3

  def sign(data) do
    secret = Application.get_env(:pokerplan, :auth_token_secret)
    Phoenix.Token.sign(PokerplanWeb.Endpoint, secret, data)
  end

  def verify(token) do
    secret = Application.get_env(:pokerplan, :auth_token_secret)
    Phoenix.Token.verify(PokerplanWeb.Endpoint, secret, token, max_age: @max_age)
  end
end
