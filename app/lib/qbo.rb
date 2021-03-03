# frozen_string_literal: true

module Qbo

  # '3481', # 40003 Sales:Taxable Sales
  # '3549', # 25500 *Sales Tax Payable
  # '3557', # 40100 Freight Income
  # '3454', # 43000 Sales Discounts
  # '3483', # 10010 Mollusk West Checking 5421 (credit cards)
  # '3487', # 10025 PayPal
  # '3504', # 22050 Gift Certificates Outstanding
  # '3476', # 50000 Cost of Goods Sold
  # '3558', # 10045 Petty Cash - San Francisco
  # '3682', # 10048 Petty Cash - Santa Barbara
  # '3628', # 10047 Petty Cash - Venice Beach

  ACCOUNT_ID_BY_OUTLET = {
    'Web' => '3652', # 11137 Finished Goods - Shopify,
    'San Francisco' => '3617', # 11001 Inventory Asset - San Francisco
    'Santa Barbara' => '3677', # 11005 Inventory Account - Santa Barbara
    'Silver Lake' => '3618', # 11002 Inventory Asset - Silver Lake
    'Venice Beach' => '3626' # 11003 Inventory Asset - Venice Beach
  }.freeze

# San Fran below needs to now be mollusk west, what will this affect beyond refunds
# "Mollusk West 300000000000824363"
# "San Fran 300000000000824364"
# "Santa Barbara 300000000000880547"
# "Silver Lake 300000000000824366"
# "Venice Beach 300000000000824365"

  CLASS_ID_BY_OUTLET = {
    'San Francisco' => 300_000_000_000_824_364,
    'Santa Barbara' => 300_000_000_000_880_547,
    'Silver Lake' => 300_000_000_000_824_366,
    'Venice Beach' => 300_000_000_000_824_365
  }.freeze

  CUSTOMER_ID_BY_OUTLET = {
    'San Francisco' => 24913,
    'Santa Barbara' => 26373,
    'Silver Lake' => 24914,
    'Venice Beach' => 24918
  }.freeze

  TAX_ITEM_ID_BY_OUTLET = {
    'San Francisco' => '172116',
    'Santa Barbara' => '182878',
    'Silver Lake' => '174884',
    'Venice Beach' => '181525'
  }.freeze

  CREDIT_CARD_PAYMENT_ID_BY_OUTLET = {
    'San Francisco' => '181526',
    'Santa Barbara' => '182879',
    'Silver Lake' => '181528',
    'Venice Beach' => '181529'
  }.freeze

  # Shopify
  SHOPIFY_CUSTOMER_ID = 24694
  WHOLESALE_SHOPIFY_CUSTOMER_ID = 26037

  MOLLUSK_WEST_CLASS = 300_000_000_000_824_363

  def self.token
    QboToken.last.refresh_if_necessary
  end

  def self.realm_id
    QboToken.last.realm_id
  end

  def self.service_params
    sleep(0.2)
    { access_token: token, company_id: realm_id }
  end

  def self.list_items
    Quickbooks::Service::Item.new(service_params).all
  end

  def self.list_accounts
    Quickbooks::Service::Account.new(service_params).all
  end

  def self.list_classes
    Quickbooks::Service::Class.new(service_params).all
  end

  def self.list_customers
    Quickbooks::Service::Customer.new(service_params).all
  end

  def self.sales_receipt_line_item(params, receipt_details)
    line = Quickbooks::Model::Line.new(params)

    line.sales_item! do |detail|
      receipt_details.each do |key, value|
        detail.send("#{key}=", value)
      end
    end
    line
  end

  def self.sales_receipt(params)
    Quickbooks::Model::SalesReceipt.new(params)
  end

  def self.create_sales_receipt(sales_receipt)
    service = Quickbooks::Service::SalesReceipt.new(service_params)

    service.create(sales_receipt)
  end

  def self.create_journal_entry(journal_entry)
    service = Quickbooks::Service::JournalEntry.new(service_params)

    service.create(journal_entry)
  end

  def self.delete_journal_entry(journal_entry_id)
    service = Quickbooks::Service::JournalEntry.new(service_params)
    journal_entry = service.fetch_by_id(journal_entry_id)
    service.delete(journal_entry)
  end

  def self.journal_entry_line_item(params, entry_details)
    line = Quickbooks::Model::Line.new(params)

    line.journal_entry! do |detail|
      entry_details.each do |key, value|
        detail.send("#{key}=", value)
      end
    end
    line
  end

  def self.base_ref(id)
    Quickbooks::Model::BaseReference.new(id)
  end

  def self.journal_entry(params)
    Quickbooks::Model::JournalEntry.new(params)
  end
end
