defmodule Test2Web.UserSocket do
  @moduledoc """
  Socket for handling WebSocket connections from Svelte frontend.
  """
  
  use Phoenix.Socket
  
  # Channels
  channel "dashboard:*", Test2Web.DashboardChannel
  
  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end
  
  @impl true
  def id(_socket), do: nil
end