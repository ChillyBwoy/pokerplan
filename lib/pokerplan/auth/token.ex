defmodule Pokerplan.Auth.Token do
  # TODO: Move this to config
  @sign_salt "UeuL(51vxR=V"
  @max_age 60 * 60 * 24 * 3

  def sign(data) do
    Phoenix.Token.sign(PokerplanWeb.Endpoint, @sign_salt, data)
  end

  def verify(token) do
    Phoenix.Token.verify(PokerplanWeb.Endpoint, @sign_salt, token, max_age: @max_age)
  end
end
