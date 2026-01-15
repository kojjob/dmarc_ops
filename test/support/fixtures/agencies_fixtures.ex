defmodule DmarcOps.AgenciesFixtures do
  @moduledoc """
  Test fixtures for agency-related tests.
  """

  alias DmarcOps.Agencies

  @doc """
  Generate an agency with unique attributes.
  """
  def agency_fixture(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    {:ok, agency} =
      attrs
      |> Enum.into(%{
        name: "Test Agency #{unique}",
        slug: "test-agency-#{unique}"
      })
      |> Agencies.create_agency()

    agency
  end
end
