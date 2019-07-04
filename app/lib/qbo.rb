module Qbo
  # Vend
  SF_CUSTOMER_ID = 24913.freeze
  VENICE_CUSTOMER_ID = 24918.freeze
  SILVER_LAKE_CUSTOMER_ID = 24914.freeze

  SAN_FRAN_CLASS = 300000000000824364.freeze
  SILVER_LAKE_CLASS = 300000000000824366.freeze
  VENICE_BEACH_CLASS = 300000000000824365.freeze

  # Shopify
  SHOPIFY_CUSTOMER_ID = 24694.freeze

  MOLLUSK_WEST_CLASS = 300000000000824363.freeze  

  def self.token
    @token ||= QboToken.last.refresh
  end

  def self.realm_id
    @realm_id ||= QboToken.last.realm_id
  end

  def self.service_params
    { access_token: token, company_id: realm_id }
  end

  def self.sales_receipt_line_item(params, receipt_details)
    line = Quickbooks::Model::Line.new(params)

    line.sales_item! do |detail|
      entry_details.each do |key, value|
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

  def self.create_journal_entry(journal_entry)
    service = Quickbooks::Service::JournalEntry.new
    service.access_token = Qbo.token
    service.company_id = QboToken.last.realm_id

    service.create(journal_entry)
  end
end
