defmodule Test2.Invoices.Generator do
  @moduledoc """
  Generates random invoice data for the real-time dashboard demo.
  
  Creates realistic e-commerce invoice data with random companies,
  amounts, and invoice numbers.
  """
  
  alias Test2.Invoices.Invoice
  alias Test2.Repo
  
  @company_names [
    "Acme Corp", "Global Industries", "Tech Solutions Ltd", "Digital Dynamics",
    "Innovation Hub", "Future Systems", "Alpha Technologies", "Beta Enterprises",
    "Gamma Solutions", "Delta Services", "Omega Corporation", "Zenith Industries",
    "Apex Systems", "Prime Tech", "Elite Solutions", "Summit Corp",
    "Pinnacle Group", "Premier Systems", "Excellence Ltd", "Superior Tech",
    "Advanced Solutions", "Modern Industries", "Progressive Corp", "Dynamic Systems",
    "Innovative Tech", "Creative Solutions", "Strategic Industries", "Professional Services",
    "Enterprise Systems", "Commercial Tech", "Business Solutions", "Corporate Industries"
  ]
  
  @product_types [
    "Software License", "Hardware Equipment", "Consulting Services", "Training Program",
    "Cloud Services", "Technical Support", "Professional Services", "Digital Marketing",
    "Web Development", "Mobile App", "Data Analytics", "Security Services",
    "Hosting Services", "Domain Registration", "SSL Certificate", "API Access",
    "Database License", "Storage Solutions", "Backup Services", "Monitoring Tools"
  ]
  
  # SADC (Southern African Development Community) countries
  @sadc_countries [
    "South Africa", "Botswana", "Zimbabwe", "Zambia", "Namibia", 
    "Lesotho", "Eswatini", "Mozambique", "Malawi", "Tanzania", 
    "Angola", "Democratic Republic of Congo", "Madagascar", "Mauritius", "Seychelles"
  ]
  
  @payment_mechanisms [
    "Bank Transfer", "Letter of Credit", "Cash in Advance", 
    "Open Account", "Documentary Collection"
  ]
  
  # Risk profile weights: 60% Green, 25% Amber, 15% Red
  @risk_profiles [
    {"Green", 60}, {"Amber", 25}, {"Red", 15}
  ]
  
  @doc """
  Generates a single random invoice and saves it to the database.
  
  Returns `{:ok, invoice}` on success or `{:error, changeset}` on failure.
  """
  def generate_random_invoice do
    attrs = %{
      invoice_number: generate_invoice_number(),
      invoice_date: DateTime.utc_now(),
      seller_name: random_company_name(),
      buyer_name: random_company_name(),
      subtotal: generate_random_amount(),
      exporting_country: random_sadc_country(),
      importing_country: random_sadc_country(),
      payment_mechanism: random_payment_mechanism(),
      risk_profile: weighted_random_risk_profile()
    }
    
    %Invoice{}
    |> Invoice.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Generates a batch of random invoices.
  
  Returns a list of `{:ok, invoice}` or `{:error, changeset}` tuples.
  """
  def generate_batch(count) when count > 0 do
    1..count
    |> Enum.map(fn _ -> generate_random_invoice() end)
  end
  
  @doc """
  Generates a unique invoice number in format: INV-YYYYMMDD-XXXX
  """
  def generate_invoice_number do
    date_part = Date.utc_today() |> Date.to_string() |> String.replace("-", "")
    random_part = :rand.uniform(9999) |> Integer.to_string() |> String.pad_leading(4, "0")
    timestamp_part = System.system_time(:millisecond) |> rem(1000) |> Integer.to_string()
    
    "INV-#{date_part}-#{random_part}#{timestamp_part}"
  end
  
  @doc """
  Generates a random amount between $10.00 and $5000.00
  """
  def generate_random_amount do
    # Generate amount between 1000 and 500000 cents, then convert to dollars
    cents = :rand.uniform(499_000) + 1000
    Decimal.new(cents) |> Decimal.div(100)
  end
  
  @doc """
  Returns a random company name from the predefined list
  """
  def random_company_name do
    Enum.random(@company_names)
  end
  
  @doc """
  Returns a random product type for invoice description
  """
  def random_product_type do
    Enum.random(@product_types)
  end
  
  @doc """
  Generates invoice data for testing purposes without saving to database
  """
  def generate_test_data do
    %{
      invoice_number: generate_invoice_number(),
      invoice_date: DateTime.utc_now(),
      seller_name: random_company_name(),
      buyer_name: random_company_name(),
      subtotal: generate_random_amount(),
      product_type: random_product_type(),
      exporting_country: random_sadc_country(),
      importing_country: random_sadc_country(),
      payment_mechanism: random_payment_mechanism(),
      risk_profile: weighted_random_risk_profile()
    }
  end
  
  @doc """
  Returns a random SADC country
  """
  def random_sadc_country do
    Enum.random(@sadc_countries)
  end
  
  @doc """
  Returns a random payment mechanism
  """
  def random_payment_mechanism do
    Enum.random(@payment_mechanisms)
  end
  
  @doc """
  Returns a weighted random risk profile: 60% Green, 25% Amber, 15% Red
  """
  def weighted_random_risk_profile do
    # Create a weighted list based on probabilities
    weighted_list = 
      Enum.flat_map(@risk_profiles, fn {profile, weight} ->
        List.duplicate(profile, weight)
      end)
    
    Enum.random(weighted_list)
  end
end