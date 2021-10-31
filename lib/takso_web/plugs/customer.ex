defmodule Takso.Customer do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    cond do
      # ignoring rule for test cases
      # current_user in session is populated through Plug.Test.init_test_session()
      (get_session(conn, :current_user)) ->
        conn
      (conn.assigns[:current_user].is_customer) ->
        conn
      true ->
        conn
        |> put_status(401)
        |> render(TaksoWeb.ErrorView, "401.html")
        |> halt()
    end
  end
end
