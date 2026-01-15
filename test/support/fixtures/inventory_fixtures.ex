defmodule DmarcOps.InventoryFixtures do
  @moduledoc """
  Test fixtures for `DmarcOps.Inventory` context.
  """

  alias DmarcOps.Inventory

  def valid_domain_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "domain-#{System.unique_integer([:positive])}.com"
    })
  end

  def domain_fixture(attrs \\ %{}) do
    {:ok, domain} =
      attrs
      |> valid_domain_attributes()
      |> Inventory.create_domain()

    domain
  end
end
