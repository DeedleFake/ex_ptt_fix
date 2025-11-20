defmodule ExPttFix.Xdo do
  @moduledoc """
  This module provides functions to send key events to the X server
  using xdo.
  """

  @spec keypress(down :: boolean(), key :: String.t()) :: :ok
  def keypress(true, key) when is_binary(key), do: keydown(key)
  def keypress(false, key) when is_binary(key), do: keyup(key)

  @spec keydown(String.t()) :: :ok
  def keydown(key) when is_binary(key) do
    xdotool(["keydown", key])
  end

  @spec keyup(String.t()) :: :ok
  def keyup(key) when is_binary(key) do
    xdotool(["keyup", key])
  end

  defp xdotool(args) when is_list(args) do
    xdotool = System.find_executable("xdotool")
    {_, 0} = System.cmd(xdotool, args)
    :ok
  end
end
