defmodule HexMirror.Mirror do
  @moduledoc """
This module is responsible for actually downloading the hex registry, and then downloading all packages to disk
"""

  def fetch do
    ensure_tarball_dir()
    Hex.Utils.ensure_registry!()
    Hex.Registry.all_packages()
    |> Enum.each(fn(pkg) -> fetch_versions(pkg)end)
  end

  def tarball_path, do: Application.get_env(:hex_mirror, :tarball_path, Path.expand("./tarballs"))

  defp fetch_versions(package) do
    package
    |> Hex.Registry.get_versions
    |> Enum.each(fn(version) ->
      fetch_version(package, version)
    end)
  end

  defp version_path(package, version), do: "#{tarball_path}/#{package}-#{version}.tar"

  defp fetch_version(package, version) do
    url = "https://repo.hex.pm/tarballs/#{package}-#{version}.tar"

    if File.exists?(version_path(package, version)) do
      {:ok, :already_downloaded}
    else
      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          File.write!(version_path(package, version), body)
          IO.puts "Downloading #{package} #{version}"
          {:ok, :downloaded}
        {:error, %HTTPoison.Error{id: id, reason: reason}} ->
          IO.puts "*** Error #{id}: downloading #{package} #{version}"
          IO.puts "*** Reason: #{reason}"
      end
    end
  end

  defp ensure_tarball_dir do
    path = tarball_path
    :ok = File.mkdir_p(path)
  end
end
