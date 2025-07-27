defmodule Test2Web.Plugs.CORS do
  @moduledoc """
  Simple CORS plug for development to allow Svelte frontend communication.
  """
  
  import Plug.Conn
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    conn
    |> put_resp_header("access-control-allow-origin", "http://localhost:5173")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
    |> put_resp_header("access-control-allow-credentials", "true")
    |> handle_preflight()
  end
  
  defp handle_preflight(%{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(200, "")
    |> halt()
  end
  
  defp handle_preflight(conn), do: conn
end