defmodule Identicon do
  alias Identicon.Image
  require Integer

  @moduledoc """
  Documentation for `Identicon`.
  """
  @spec from_string(binary) :: term
  def from_string(string) when is_binary(string) do
    string
    |> hash()
    |> pick_color()
    |> build_grid()
    |> remove_odd_grid_squares()
    |> build_pixel_map()
    |> draw_image()
    |> save_image(string)
  end

  defp hash(string) when is_binary(string) do
    seed =
      :crypto.hash(:md5, string)
      |> :binary.bin_to_list()

    %Image{seed: seed}
  end

  defp pick_color(%Image{seed: [r, g, b | _]} = image) do
    %Image{image | color: {r, g, b}}
  end

  defp build_grid(%Image{seed: seed} = image) do
    grid =
      seed
      |> Enum.chunk_every(3, 3, :discard)
      |> Enum.flat_map(&mirror_row/1)
      |> Enum.with_index()

    %Image{image | grid: grid}
  end

  defp mirror_row([r, g, b]) do
    [r, g, b, g, r]
  end

  defp remove_odd_grid_squares(%Image{grid: grid} = image) do
    grid = grid |> Enum.filter(fn {code, _index} -> Integer.is_even(code) end)

    %Image{image | grid: grid}
  end

  defp build_pixel_map(%Image{grid: grid} = image) do
    pixel_map =
      grid
      |> Enum.map(fn {_code, index} ->
        horizontal = rem(index, 5) * 50
        vertical = div(index, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Image{image | pixel_map: pixel_map}
  end

  defp draw_image(%Image{color: color, pixel_map: pixel_map}) do
    image = :egd.create(250, 250)

    fill = :egd.color(color)

    pixel_map
    |> Enum.each(fn {top_left, bottom_right} ->
      :egd.filledRectangle(image, top_left, bottom_right, fill)
    end)

    :egd.render(image)
  end

  defp save_image(image_file, file_name) do
    File.write("#{file_name}.png", image_file)
  end
end
