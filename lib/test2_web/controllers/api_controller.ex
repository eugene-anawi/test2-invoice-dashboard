defmodule Test2Web.ApiController do
  use Test2Web, :controller
  
  alias Test2.Streaming.Coordinator
  alias Test2.Invoices.Stats
  
  def stats(conn, _params) do
    stats = Stats.get_current_stats()
    json(conn, %{data: stats})
  end
  
  def invoices(conn, params) do
    limit = Map.get(params, "limit", "50") |> String.to_integer()
    invoices = Stats.get_recent_invoices(limit)
    json(conn, %{data: invoices})
  end
  
  def start_generation(conn, _params) do
    case Coordinator.start_generation() do
      {:ok, :started} ->
        json(conn, %{status: "success", message: "Generation started"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: to_string(reason)})
    end
  end
  
  def stop_generation(conn, _params) do
    case Coordinator.stop_generation() do
      {:ok, :stopping} ->
        json(conn, %{status: "success", message: "Generation stopping"})
      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{status: "error", message: to_string(reason)})
    end
  end
  
  def system_status(conn, _params) do
    status = Coordinator.get_status()
    json(conn, %{data: status})
  end
end