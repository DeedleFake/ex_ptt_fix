defmodule ExPttFix.Xdo do
  @moduledoc """
  This module provides functions to send key events to the X server
  using xdo.
  """

  def keypress(true, key) when is_binary(key), do: keydown(key)
  def keypress(false, key) when is_binary(key), do: keyup(key)

  def keydown(name) when is_binary(name) do
    xdotool(["keydown", name])
  end

  def keyup(name) when is_binary(name) do
    xdotool(["keyup", name])
  end

  defp xdotool(args) when is_list(args) do
    xdotool = System.find_executable("xdotool")
    {_, 0} = System.cmd(xdotool, args)
    :ok
  end
end
