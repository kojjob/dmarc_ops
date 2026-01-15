defmodule DmarcOps.InventoryTest do
  use DmarcOps.DataCase

  alias DmarcOps.Inventory
  alias DmarcOps.Inventory.Domain

  import DmarcOps.AccountsFixtures
  import DmarcOps.AgenciesFixtures
  import DmarcOps.InventoryFixtures

  describe "domains" do
    setup do
      agency = agency_fixture()
      %{agency: agency}
    end

    test "list_domains/1 returns all domains for an agency", %{agency: agency} do
      domain = domain_fixture(agency_id: agency.id)
      other_agency = agency_fixture()
      _other_domain = domain_fixture(agency_id: other_agency.id)

      assert Inventory.list_domains(agency.id) == [domain]
    end

    test "get_domain/2 returns the domain with given id", %{agency: agency} do
      domain = domain_fixture(agency_id: agency.id)
      assert Inventory.get_domain(agency.id, domain.id) == domain
    end

    test "get_domain/2 returns nil for domain from another agency", %{agency: agency} do
      other_agency = agency_fixture()
      domain = domain_fixture(agency_id: other_agency.id)
      assert Inventory.get_domain(agency.id, domain.id) == nil
    end

    test "create_domain/1 with valid data creates a domain", %{agency: agency} do
      valid_attrs = %{name: "example.com", agency_id: agency.id}

      assert {:ok, %Domain{} = domain} = Inventory.create_domain(valid_attrs)
      assert domain.name == "example.com"
      assert domain.agency_id == agency.id
      assert domain.status == :pending
      assert domain.current_policy == :none
      assert domain.spf_status == false
      assert domain.dkim_status == false
      assert domain.dmarc_status == false
      assert domain.mta_sts_mode == :none
      assert domain.dns_verification_code != nil
    end

    test "create_domain/1 auto-generates verification code", %{agency: agency} do
      attrs = %{name: "test.com", agency_id: agency.id}
      {:ok, domain1} = Inventory.create_domain(attrs)
      {:ok, domain2} = Inventory.create_domain(%{attrs | name: "test2.com"})

      assert domain1.dns_verification_code != nil
      assert domain2.dns_verification_code != nil
      assert domain1.dns_verification_code != domain2.dns_verification_code
    end

    test "create_domain/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Inventory.create_domain(%{})
    end

    test "create_domain/1 enforces unique domain per agency", %{agency: agency} do
      attrs = %{name: "duplicate.com", agency_id: agency.id}
      {:ok, _domain} = Inventory.create_domain(attrs)

      assert {:error, changeset} = Inventory.create_domain(attrs)
      errors = errors_on(changeset)
      # Composite unique constraint can appear on either field
      assert "has already been taken" in Map.get(errors, :name, []) or
             "has already been taken" in Map.get(errors, :agency_id, [])
    end

    test "create_domain/1 allows same domain for different agencies", %{agency: agency} do
      other_agency = agency_fixture()
      attrs = %{name: "shared.com", agency_id: agency.id}
      other_attrs = %{name: "shared.com", agency_id: other_agency.id}

      assert {:ok, domain1} = Inventory.create_domain(attrs)
      assert {:ok, domain2} = Inventory.create_domain(other_attrs)
      assert domain1.name == domain2.name
      assert domain1.agency_id != domain2.agency_id
    end

    test "update_domain/2 with valid data updates the domain", %{agency: agency} do
      domain = domain_fixture(agency_id: agency.id)
      update_attrs = %{status: :verified, spf_status: true}

      assert {:ok, %Domain{} = updated} = Inventory.update_domain(domain, update_attrs)
      assert updated.status == :verified
      assert updated.spf_status == true
    end

    test "delete_domain/1 deletes the domain", %{agency: agency} do
      domain = domain_fixture(agency_id: agency.id)
      assert {:ok, %Domain{}} = Inventory.delete_domain(domain)
      assert Inventory.get_domain(agency.id, domain.id) == nil
    end

    test "change_domain/1 returns a domain changeset", %{agency: agency} do
      domain = domain_fixture(agency_id: agency.id)
      assert %Ecto.Changeset{} = Inventory.change_domain(domain)
    end
  end

  describe "domain status transitions" do
    setup do
      agency = agency_fixture()
      domain = domain_fixture(agency_id: agency.id)
      %{agency: agency, domain: domain}
    end

    test "verify_domain/1 updates status from pending to verified", %{domain: domain} do
      assert {:ok, verified} = Inventory.verify_domain(domain)
      assert verified.status == :verified
    end

    test "set_enforcement_policy/2 updates current_policy", %{domain: domain} do
      {:ok, domain} = Inventory.verify_domain(domain)
      assert {:ok, enforced} = Inventory.set_enforcement_policy(domain, :quarantine)
      assert enforced.current_policy == :quarantine
    end
  end
end
