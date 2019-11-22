# Example Order Row:

#   {
#     'RefNumber'=>'4153',
#     'Customer'=>'J.Crew NC DC',
#     'TxnDate'=>'11/21/2019',
#     'CustomerPO'=>'4153',
#     'Department'=>'Mens',
#     'Location'=>'SUM20',
#     'StartShip'=>'05/01/2020',
#     'CancelDate'=>'05/28/2020',
#     'ItemName'=>'MS2000-WSP-S',
#     'QuantityOrdered'=>'1',
#     'Sales Analysis Name'=>'J.Crew'
#   }

class WholesaleOrder < ApplicationRecord
  has_many :wholesale_order_items

  SAVED_HEADERS = {
    'RefNumber' => :ref_number,
    'Customer' => :customer,
    'TxnDate' => :txn_date,
    'CustomerPO' => :customer_po,
    'Department' => :department,
    'Location' => :location,
    'StartShip' => :start_ship,
    'CancelDate' => :cancel_date,
    'ItemName' => :item_name,
    'QuantityOrdered' => :quantity_ordered
  }

  def self.pull_sheet
    GoogleClient.sheet_values(GoogleClient::WHOLESALE_ORDERS, GoogleClient::WHOLESALE_ORDER_SHEET)
  end

  def self.process_orders
    orders = pull_sheet.reject! { |order| order['RefNumber'].blank? }

    orders_by_customer = Hash.new { |h,k| h[k] = [] }

    orders.each do |order|
      orders_by_customer[order['Customer']] << order
    end

    orders_by_customer
  end

  def self.create_orders
    wholesale_order = create() #link customer here

    process_orders.each do |customer, orders|
      orders.each do |order|
        formatted_order = {}
        order.except('Sales Analysis Name').each do |header, value|
          if ['TxnDate', 'StartShip', 'CancelDate'].include?(header)
            formatted_order[SAVED_HEADERS[header]] = Date.strptime(value, "%m/%d/%Y")
          else
            formatted_order[SAVED_HEADERS[header]] = value
          end
        end
        
        wholesale_order.wholesale_order_items << WholesaleOrderItem.new(formatted_order)
      end
    end
  end

  def post_to_sos
  end
end

# == Schema Information
#
# Table name: wholesale_orders
#
#  id         :bigint(8)        not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sos_id     :integer
#
