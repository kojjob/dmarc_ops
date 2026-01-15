defmodule DmarcOps.Repo.Migrations.CreateDomains do
  use Ecto.Migration

  def change do
    create table(:domains, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :agency_id, references(:agencies, on_delete: :delete_all, type: :binary_id), null: false
      add :name, :string, null: false
      add :status, :string, default: "pending"
      add :current_policy, :string, default: "none"
      add :target_policy, :string

      # DNS authentication status
      add :spf_status, :boolean, default: false
      add :dkim_status, :boolean, default: false
      add :dmarc_status, :boolean, default: false

      # MTA-STS configuration
      add :mta_sts_mode, :string, default: "none"
      add :mta_sts_max_age, :integer, default: 86400

      # Verification
      add :dns_verification_code, :string

      # Enforcement ramp automation
      add :ramp_schedule, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:domains, [:agency_id, :name])
    create index(:domains, [:agency_id])
    create index(:domains, [:status])
  end
end
