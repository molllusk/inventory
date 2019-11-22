# Example Order Row:

#   {
#     "RefNumber"=>"4153",
#     "Customer"=>"J.Crew NC DC",
#     "TxnDate"=>"11/21/2019",
#     "CustomerPO"=>"4153",
#     "Department"=>"Mens",
#     "Location"=>"SUM20",
#     "StartShip"=>"05/01/2020",
#     "CancelDate"=>"05/28/2020",
#     "ItemName"=>"MS2000-WSP-S",
#     "QuantityOrdered"=>"1",
#     "Sales Analysis Name"=>"J.Crew"
#   }

class WholesaleOrder < ApplicationRecord
  def self.pull_sheet
    GoogleClient.sheet_values(GoogleClient::WHOLESALE_ORDERS, GoogleClient::WHOLESALE_ORDER_SHEET)
  end

  def self.process_orders
    orders = pull_sheet.reject! { |order| order["RefNumber"].blank? }

    orders_by_customer = Hash.new { |h,k| h[k] = [] }

    orders.each do |order|
      orders_by_customer[order['Customer']] << order
    end

    orders_by_customer
  end

  def post_to_sos
  end
end
