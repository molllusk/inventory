class DailyOrder < ApplicationRecord
  has_many :orders, dependent: :destroy

  ACCOUNT_ID_BY_OUTLET = {
    'San Francisco' => '3617', # 11001 Inventory Asset - San Francisco
    'Silver Lake' => '3618', # 11002 Inventory Asset - Silver Lake
    'Venice Beach' => '3626' # 11003 Inventory Asset - Venice Beach
  }

  CLASS_ID_BY_OUTLET = {
    'San Francisco' => Qbo::SAN_FRAN_CLASS,
    'Silver Lake' => Qbo::SILVER_LAKE_CLASS,
    'Venice Beach' => Qbo::VENICE_BEACH_CLASS
  }

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop (San Francisco)<br />4500 Irving Street<br />San Francisco, CA 94122-1132',
    'Venice Beach' => 'Mollusk Surf Shop (Venice Beach)<br />1600 Pacific Avenue<br />Venice Beach, CA 90291-9998',
    'Silver Lake' => 'Mollusk Surf Shop (Silver Lake)<br />3511 W Sunset Blvd<br />Los Angeles, CA 90026-9998'
  }

  def self.last_po(outlet)
    where(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key(outlet)).maximum(:po_id).to_i
  end

  def to_pdf
    # create an instance of ActionView, so we can use the render method outside of a controller
    av = ActionView::Base.new
    av.view_paths = ActionController::Base.view_paths

    # need these in case your view constructs any links or references any helper methods.
    av.class_eval do
      include Rails.application.routes.url_helpers
      include ApplicationHelper
    end

    pdf_html = av.render template: 'daily_orders/po.html.erb', layout: nil, locals: { daily_order: self }

    HyPDF.htmltopdf(
        pdf_html,
        test: ENV['HYPDF_MODE'] == 'test'
      )[:pdf]
  end

  def pdf_filename
    "Mollusk_Inventory_Transfer_PO_#{display_po.gsub(/\s+/,'_')}.pdf"
  end

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def po_stem
    outlet_name.split.map(&:first).join.upcase
  end

  def display_po
    "#{po_stem} #{po_id}"
  end

  def create_consignment

  end

  def journal_entry_params
    {
      txn_date: date,
      doc_number: "APP-DO-#{id}"
    }
  end

  # def journal_line_item_details
  #   details = []
  #   vend_sales_costs.each do |sales_cost|
  #     outlet = sales_cost.outlet_id

  #     details << {
  #       account_id: '3476', # cost of goods sold
  #       amount: sales_cost.cost,
  #       description: 'Total Cost of Sales Vend',
  #       posting_type: 'Debit',
  #       class_id: CLASS_ID_BY_OUTLET[sales_cost.outlet_name]
  #     }

  #     details << {
  #       account_id: ACCOUNT_ID_BY_OUTLET[sales_cost.outlet_name], # Location specific Inventory Asset
  #       amount: sales_cost.cost,
  #       description: 'Total Cost of Sales Vend',
  #       posting_type: 'Credit',
  #       class_id: CLASS_ID_BY_OUTLET[sales_cost.outlet_name]
  #     }
  #   end
  #   details
  # end

  # def journal_entry
  #   journal_entry = Qbo.journal_entry(journal_entry_params)

  #   journal_line_item_details.each do |details|
  #     line_item_params = {
  #       amount: details[:amount],
  #       description: details[:description]
  #     }

  #     journal_entry_line_detail = {
  #       account_ref: Qbo.base_ref(details[:account_id]),
  #       class_ref: Qbo.base_ref(details[:class_id]),
  #       posting_type: details[:posting_type]
  #     }

  #     line_item = Qbo.journal_entry_line_item(line_item_params, journal_entry_line_detail)
  #     journal_entry.line_items << line_item
  #   end

  #   journal_entry
  # end

  # def post_to_qbo
  #   if vend_sales_cost_sales.present?
  #     qbo = Qbo.create_journal_entry(journal_entry)
  #     update_attribute(:qbo_id, qbo.id) unless qbo.blank?
  #   end
  # end

  def ship_to_address
    PO_ADDRESSES[outlet_name]
  end

  def send_po
    ApplicationMailer.po_pdf(self).deliver
  end

  def total_items
    orders.reduce(0) { |sum, order| sum + order.quantity }
  end

  def total_cost
    orders.reduce(0) { |sum, order| sum + (order.quantity * order.cost) }
  end

  def vend_consignment_url
    "https://mollusksurf.vendhq.com/consignment/#{@daily_order.vend_consignment_id}" if vend_consignment_id.present?
  end
end

# == Schema Information
#
# Table name: daily_orders
#
#  id                  :bigint(8)        not null, primary key
#  date                :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  outlet_id           :string
#  po_id               :integer
#  qbo_id              :bigint(8)
#  vend_consignment_id :string
#
