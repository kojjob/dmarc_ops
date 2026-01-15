defmodule DmarcOps.Repo.Migrations.CreateAgencies do
  use Ecto.Migration

  def change do
    create table(:agencies, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :plan, :string, default: "starter"
      add :billing_status, :string, default: "trial"
      add :settings, :map, default: %{}
      add :custom_branding, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agencies, [:slug])

    # Add agency_id to users table
    alter table(:users) do
      add :agency_id, references(:agencies, on_delete: :delete_all, type: :binary_id)
      add :role, :string, default: "member"
    end

    create index(:users, [:agency_id])
  end
end
