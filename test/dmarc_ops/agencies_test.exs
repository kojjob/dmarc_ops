defmodule DmarcOps.AgenciesTest do
  use DmarcOps.DataCase, async: true

  alias DmarcOps.Agencies
  alias DmarcOps.Agencies.Agency

  describe "create_agency/1" do
    test "creates agency with valid attrs" do
      attrs = %{name: "Acme Agency", slug: "acme-agency"}
      assert {:ok, %Agency{} = agency} = Agencies.create_agency(attrs)
      assert agency.name == "Acme Agency"
      assert agency.slug == "acme-agency"
      assert agency.plan == "starter"
      assert agency.billing_status == "trial"
    end

    test "generates slug from name if not provided" do
      attrs = %{name: "Best Marketing Agency"}
      assert {:ok, %Agency{} = agency} = Agencies.create_agency(attrs)
      assert agency.slug == "best-marketing-agency"
    end

    test "returns error with missing name" do
      attrs = %{slug: "test"}
      assert {:error, changeset} = Agencies.create_agency(attrs)
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error with duplicate slug" do
      attrs = %{name: "Agency One", slug: "unique-slug"}
      assert {:ok, _agency1} = Agencies.create_agency(attrs)

      attrs2 = %{name: "Agency Two", slug: "unique-slug"}
      assert {:error, changeset} = Agencies.create_agency(attrs2)
      assert %{slug: ["has already been taken"]} = errors_on(changeset)
    end

    test "validates plan values" do
      attrs = %{name: "Test Agency", plan: "invalid_plan"}
      assert {:error, changeset} = Agencies.create_agency(attrs)
      assert %{plan: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "get_agency/1" do
    test "returns agency when exists" do
      {:ok, agency} = Agencies.create_agency(%{name: "Get Test"})
      assert Agencies.get_agency(agency.id) == agency
    end

    test "returns nil when not found" do
      assert Agencies.get_agency(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_agency_by_slug/1" do
    test "returns agency by slug" do
      {:ok, agency} = Agencies.create_agency(%{name: "Slug Test", slug: "slug-test"})
      assert Agencies.get_agency_by_slug("slug-test") == agency
    end

    test "returns nil when slug not found" do
      assert Agencies.get_agency_by_slug("nonexistent") == nil
    end
  end

  describe "update_agency/2" do
    test "updates agency with valid attrs" do
      {:ok, agency} = Agencies.create_agency(%{name: "Original"})
      assert {:ok, updated} = Agencies.update_agency(agency, %{name: "Updated"})
      assert updated.name == "Updated"
    end

    test "updates plan" do
      {:ok, agency} = Agencies.create_agency(%{name: "Plan Test"})
      assert {:ok, updated} = Agencies.update_agency(agency, %{plan: "pro"})
      assert updated.plan == "pro"
    end
  end

  describe "delete_agency/1" do
    test "deletes agency" do
      {:ok, agency} = Agencies.create_agency(%{name: "Delete Test"})
      assert {:ok, _deleted} = Agencies.delete_agency(agency)
      assert Agencies.get_agency(agency.id) == nil
    end
  end

  describe "list_agencies/0" do
    test "returns all agencies" do
      {:ok, agency1} = Agencies.create_agency(%{name: "Agency 1"})
      {:ok, agency2} = Agencies.create_agency(%{name: "Agency 2"})

      agencies = Agencies.list_agencies()
      assert length(agencies) == 2
      assert agency1 in agencies
      assert agency2 in agencies
    end
  end
end
