defmodule Test2.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :invoice_number, :string, null: false
      add :invoice_date, :utc_datetime, null: false
      add :seller_name, :string, null: false
      add :buyer_name, :string, null: false
      add :subtotal, :decimal, precision: 12, scale: 2, null: false
      add :vat_amount, :decimal, precision: 12, scale: 2, null: false
      add :total_amount, :decimal, precision: 12, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:invoices, [:invoice_number])
    create index(:invoices, [:invoice_date])
    create index(:invoices, [:inserted_at])
    create index(:invoices, [:seller_name])
    create index(:invoices, [:buyer_name])
  end
end