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

  def self.journal_entry_line_item(params)
    line = Quickbooks::Model::Line.new(params)
    line.journal_entry! do |detail|
      detail.class_ref = Qbo.class_ref(Qbo::MOLLUSK_WEST_CLASS)
    end
    line
  end

  def self.journal_entry_line_item_detail(params)
    Quickbooks::Model::JournalEntryLineDetail.new(params)
  end

  def self.class_ref(id)
    Quickbooks::Model::BaseReference.new(id)
  end

  def self.account_ref(id)
    Quickbooks::Model::BaseReference.new(id)
  end

  def self.journal_entry(params)
    Quickbooks::Model::JournalEntry.new(params)
  end

  def self.create_journal_entry(journal_entry)
    service = Quickbooks::Service::JournalEntry.new
    service.access_token = token
    service.company_id = QboToken.last.realm_id

    service.create(journal_entry)
  end
end

# #Invoices, SalesReceipts etc can also be defined in a single command
# salesreceipt = Quickbooks::Model::SalesReceipt.new({
#   customer_id: 99,
#   txn_date: Date.civil(2013, 11, 20),
#   payment_ref_number: "111", #optional payment reference number/string - e.g. stripe token
#   deposit_to_account_id: 222, #The ID of the Account entity you want the SalesReceipt to be deposited to
#   payment_method_id: 333 #The ID of the PaymentMethod entity you want to be used for this transaction
# })
# salesreceipt.auto_doc_number! #allows Intuit to auto-generate the transaction number

# line_item = Quickbooks::Model::Line.new
# line_item.amount = 50
# line_item.description = "Plush Baby Doll"
# line_item.sales_item! do |detail|
#   detail.unit_price = 50
#   detail.quantity = 1
#   detail.item_id = 500 # Item (Product/Service) ID here
# end

# salesreceipt.line_items << line_item

# service = Quickbooks::Service::SalesReceipt.new({access_token: access_token, company_id: "123" })
# created_receipt = service.create(salesreceipt)

# JournalEntryLineDetail