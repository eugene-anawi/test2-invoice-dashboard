defmodule Test2.Cache.StatsCache do
  @moduledoc """
  Redis-based caching for invoice statistics.
  
  Provides fast access to frequently requested statistics
  with automatic fallback to database queries when Redis is unavailable.
  """
  
  require Logger
  
  @stats_key "invoice:stats"
  @cache_ttl 3600  # 1 hour TTL for stats cache
  
  @doc """
  Gets statistics from cache.
  
  Returns `{:ok, stats}` if found in cache, `{:error, reason}` otherwise.
  """
  def get_stats do
    case Redix.command(:redix, ["GET", @stats_key]) do
      {:ok, nil} ->
        {:error, :not_found}
        
      {:ok, json_data} ->
        try do
          stats = Jason.decode!(json_data)
          {:ok, atomize_keys(stats)}
        rescue
          error ->
            Logger.warn("Failed to decode cached stats: #{inspect(error)}")
            {:error, :decode_error}
        end
        
      {:error, reason} ->
        Logger.warn("Redis error getting stats: #{inspect(reason)}")
        {:error, :redis_error}
    end
  end
  
  @doc """
  Sets statistics in cache with TTL.
  
  Returns `:ok` on success, `{:error, reason}` on failure.
  """
  def set_stats(stats) do
    try do
      json_data = Jason.encode!(stats)
      
      case Redix.command(:redix, ["SETEX", @stats_key, @cache_ttl, json_data]) do
        {:ok, "OK"} ->
          :ok
          
        {:error, reason} ->
          Logger.warn("Redis error setting stats: #{inspect(reason)}")
          {:error, :redis_error}
      end
    rescue
      error ->
        Logger.warn("Failed to encode stats for cache: #{inspect(error)}")
        {:error, :encode_error}
    end
  end
  
  @doc """
  Clears statistics from cache.
  """
  def clear_stats do
    case Redix.command(:redix, ["DEL", @stats_key]) do
      {:ok, _count} ->
        :ok
        
      {:error, reason} ->
        Logger.warn("Redis error clearing stats: #{inspect(reason)}")
        {:error, :redis_error}
    end
  end
  
  @doc """
  Increments a specific statistic atomically in Redis.
  
  This is useful for high-frequency updates like invoice counts.
  """
  def increment_stat(field, amount \\ 1) do
    field_key = "#{@stats_key}:#{field}"
    
    case Redix.command(:redix, ["INCRBYFLOAT", field_key, amount]) do
      {:ok, new_value} ->
        {:ok, String.to_float(new_value)}
        
      {:error, reason} ->
        Logger.warn("Redis error incrementing #{field}: #{inspect(reason)}")
        {:error, :redis_error}
    end
  end
  
  @doc """
  Gets multiple statistics using Redis pipeline for efficiency.
  """
  def get_stats_pipeline do
    commands = [
      ["GET", "#{@stats_key}:count"],
      ["GET", "#{@stats_key}:total_amount"],
      ["GET", "#{@stats_key}:vat_total"],
      ["GET", "#{@stats_key}:subtotal"]
    ]
    
    case Redix.pipeline(:redix, commands) do
      {:ok, [count, total, vat, subtotal]} ->
        try do
          stats = %{
            count: parse_number(count, 0),
            total_amount: parse_number(total, 0.0),
            vat_total: parse_number(vat, 0.0),
            subtotal: parse_number(subtotal, 0.0)
          }
          
          average = if stats.count > 0, do: stats.total_amount / stats.count, else: 0.0
          {:ok, Map.put(stats, :average_amount, average)}
        rescue
          error ->
            Logger.warn("Failed to parse pipelined stats: #{inspect(error)}")
            {:error, :parse_error}
        end
        
      {:error, reason} ->
        Logger.warn("Redis pipeline error: #{inspect(reason)}")
        {:error, :redis_error}
    end
  end
  
  @doc """
  Sets multiple statistics using Redis pipeline for efficiency.
  """
  def set_stats_pipeline(stats) do
    commands = [
      ["SETEX", "#{@stats_key}:count", @cache_ttl, stats.count],
      ["SETEX", "#{@stats_key}:total_amount", @cache_ttl, stats.total_amount],
      ["SETEX", "#{@stats_key}:vat_total", @cache_ttl, stats.vat_total],
      ["SETEX", "#{@stats_key}:subtotal", @cache_ttl, stats.subtotal || 0.0],
      ["SETEX", "#{@stats_key}:average_amount", @cache_ttl, stats.average_amount || 0.0]
    ]
    
    case Redix.pipeline(:redix, commands) do
      {:ok, results} ->
        if Enum.all?(results, &(&1 == "OK")) do
          :ok
        else
          Logger.warn("Some pipeline commands failed: #{inspect(results)}")
          {:error, :partial_failure}
        end
        
      {:error, reason} ->
        Logger.warn("Redis pipeline error setting stats: #{inspect(reason)}")
        {:error, :redis_error}
    end
  end
  
  @doc """
  Gets cache information and health status.
  """
  def cache_info do
    case Redix.command(:redix, ["INFO", "memory"]) do
      {:ok, info} ->
        case Redix.command(:redix, ["TTL", @stats_key]) do
          {:ok, ttl} ->
            {:ok, %{
              redis_available: true,
              stats_ttl: ttl,
              memory_info: parse_redis_info(info)
            }}
            
          {:error, reason} ->
            {:error, reason}
        end
        
      {:error, reason} ->
        {:ok, %{
          redis_available: false,
          error: reason
        }}
    end
  end
  
  @doc """
  Checks if Redis connection is healthy.
  """
  def health_check do
    case Redix.command(:redix, ["PING"]) do
      {:ok, "PONG"} -> {:ok, :healthy}
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Private functions
  
  defp atomize_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
  
  defp parse_number(nil, default), do: default
  defp parse_number(value, _default) when is_number(value), do: value
  defp parse_number(value, default) when is_binary(value) do
    case Float.parse(value) do
      {number, _} -> number
      :error -> 
        case Integer.parse(value) do
          {number, _} -> number
          :error -> default
        end
    end
  end
  defp parse_number(_, default), do: default
  
  defp parse_redis_info(info_string) do
    info_string
    |> String.split("\r\n")
    |> Enum.filter(&String.contains?(&1, ":"))
    |> Enum.map(fn line ->
      [key, value] = String.split(line, ":", parts: 2)
      {key, value}
    end)
    |> Map.new()
  end
end