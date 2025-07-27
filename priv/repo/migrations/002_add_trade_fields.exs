defmodule Test2.Repo.Migrations.AddTradeFields do
  use Ecto.Migration

  def change do
    alter table(:invoices) do
      add :exporting_country, :string, size: 100
      add :importing_country, :string, size: 100
      add :payment_mechanism, :string, size: 100
      add :risk_profile, :string, size: 20
    end

    create index(:invoices, [:exporting_country])
    create index(:invoices, [:importing_country])
    create index(:invoices, [:risk_profile])
  end
end