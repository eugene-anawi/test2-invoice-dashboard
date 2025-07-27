defmodule Test2.Invoices.Invoice do
  @moduledoc """
  Invoice schema for the e-commerce real-time dashboard.
  
  Represents an invoice with seller, buyer, amounts and VAT calculations.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  @derive {Jason.Encoder, only: [:id, :invoice_number, :invoice_date, :seller_name, 
                                 :buyer_name, :subtotal, :vat_amount, :total_amount,
                                 :exporting_country, :importing_country, :payment_mechanism, :risk_profile]}
  
  schema "invoices" do
    field :invoice_number, :string
    field :invoice_date, :utc_datetime
    field :seller_name, :string
    field :buyer_name, :string
    field :subtotal, :decimal
    field :vat_amount, :decimal    # 15% of subtotal
    field :total_amount, :decimal  # subtotal + vat_amount
    
    # International trade fields
    field :exporting_country, :string
    field :importing_country, :string
    field :payment_mechanism, :string
    field :risk_profile, :string  # "Green", "Amber", "Red"
    
    timestamps(type: :utc_datetime)
  end
  
  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:invoice_number, :invoice_date, :seller_name, :buyer_name, :subtotal,
                    :exporting_country, :importing_country, :payment_mechanism, :risk_profile])
    |> validate_required([:invoice_number, :invoice_date, :seller_name, :buyer_name, :subtotal,
                          :exporting_country, :importing_country, :payment_mechanism, :risk_profile])
    |> validate_length(:invoice_number, min: 3, max: 50)
    |> validate_length(:seller_name, min: 2, max: 255)
    |> validate_length(:buyer_name, min: 2, max: 255)
    |> validate_length(:exporting_country, min: 2, max: 100)
    |> validate_length(:importing_country, min: 2, max: 100)
    |> validate_length(:payment_mechanism, min: 2, max: 100)
    |> validate_inclusion(:risk_profile, ["Green", "Amber", "Red"])
    |> validate_number(:subtotal, greater_than: 0)
    |> unique_constraint(:invoice_number)
    |> calculate_amounts()
  end
  
  defp calculate_amounts(changeset) do
    case get_change(changeset, :subtotal) do
      nil -> changeset
      subtotal ->
        vat_rate = Decimal.new("0.15")  # 15% VAT
        vat_amount = Decimal.mult(subtotal, vat_rate)
        total_amount = Decimal.add(subtotal, vat_amount)
        
        changeset
        |> put_change(:vat_amount, vat_amount)
        |> put_change(:total_amount, total_amount)
    end
  end
  
  @doc """
  Generates a formatted display string for the invoice
  """
  def display_summary(%__MODULE__{} = invoice) do
    "#{invoice.invoice_number} - #{invoice.seller_name} → #{invoice.buyer_name} - $#{invoice.total_amount}"
  end
  
  @doc """
  Returns the VAT rate as a percentage
  """
  def vat_rate, do: 15
end