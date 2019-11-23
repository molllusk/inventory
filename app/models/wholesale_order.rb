# Example Order Row:
#
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
  has_many :wholesale_order_items, dependent: :destroy

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

  def self.pull_customer_data_sheet
    GoogleClient.sheet_values(GoogleClient::WHOLESALE_ORDERS, GoogleClient::CUSTOMER_DATA_SHEET)
  end

  def self.process_orders
    sheet_orders = pull_sheet.reject { |order| order['RefNumber'].blank? }
    orders_by_customer = Hash.new { |h,k| h[k] = [] }

    sheet_orders.each do |order|
      orders_by_customer[order['Customer'] + order['RefNumber']] << order
    end

    orders_by_customer
  end

  def self.order_attributes(order)
    order_attrs = {}
    order.except('Sales Analysis Name', 'Department', 'ItemName', 'QuantityOrdered', 'TxnDate').each do |header, value|
      if ['StartShip', 'CancelDate'].include?(header)
        order_attrs[SAVED_HEADERS[header]] = Date.strptime(value, "%m/%d/%Y")
      else
        order_attrs[SAVED_HEADERS[header]] = value
      end
    end
    order_attrs
  end

  def self.create_orders
    wholesale_orders = []
    process_orders.each do |customer, orders|
      next if orders.blank?

      wholesale_order = create(order_attributes(orders.first)) # link customer to wholesale order has_one customer
      orders.each do |order|
        item = {
          department: order['Department'],
          item_name: order['ItemName'],
          quantity_ordered: order['QuantityOrdered'].to_i
        }
        
        wholesale_order.wholesale_order_items << WholesaleOrderItem.new(item)
      end
      wholesale_order.post_to_sos
    end
  end

  def customer_data_row
    @customer_data_row ||= WholesaleOrder.pull_customer_data_sheet.find { |customer_data| customer_data['Name'] == customer } 
  end

  def post_to_sos
    data = compile_post_data
    response = SosClient.create_sales_order(data)
    update_attribute(:sos_id, response['id'])
    update_attribute(:sos_total, response['total'])
    report_totals_to_sheet
  end

  def report_totals_to_sheet
    row = [customer_data_row['Sales Analysis Name'], location, ref_number, total_by_department['Mens'], total_by_department['Womens'], sos_total]
    GoogleClient.append_to_spreadsheet(GoogleClient::WHOLESALE_ORDERS, GoogleClient::SO_REPORT_SHEET, row)
  end

  def sos_location
    @sos_location ||= SosClient.get_locations.find { |sos_location| sos_location['name'] == location }
  end

  def sos_customer
    @sos_customer ||= SosClient.get_customers.find { |sos_customer| sos_customer['name'] == customer }
  end

  def sos_channel
    @sos_channel ||= SosClient.get_channels.find { |sos_channel| sos_channel['name'] == customer_data_row['Channel'] }
  end

  def sos_terms
    @sos_terms ||= SosClient.get_terms.find { |sos_term| sos_term['name'] == customer_data_row['Terms'] }
  end

  def sos_sales_rep
    @sos_sales_rep ||= SosClient.get_sales_reps.find { |sos_sales_rep| (sos_sales_rep['lastName'].present? ? "#{sos_sales_rep['firstName']} #{sos_sales_rep['lastName']}" : sos_sales_rep['firstName']) == customer_data_row['Sales Rep'] }
  end

  def sos_billing_contact_email
    WholesaleOrder.last.sos_customer['customFields'].find { |field| field['name'] == 'BillingEmail' }
  end

  def sos_shipping_contact_email
    WholesaleOrder.last.sos_customer['customFields'].find { |field| field['name'] == 'ShippingEmail' }
  end

  # ask about sales rep
  def compile_post_data
    defaults = {
      date: Time.now.strftime("%Y-%m-%dT%H:%M:%S"),
      depositPercent: 0.00000,
      depositAmount: 0.00000,
      subTotal: 0.00000,
      discountPercent: 0.00000,
      taxPercent: 0.00000,
      taxAmount: 0.00000,
      shippingAmount: 0.00000,
      total: 0.00000,
      discountTaxable: false,
      shippingTaxable: false,
      dropShip: false,
      billing: {
        company: '',
        contact: '',
        phone: '',
        addressName: '',
        addressType: ''
      },
      shipping: {
        company: '',
        contact: '',
        phone: '',
        addressName: '',
        addressType: ''
      }
    }

    custom_fields = [
      { id: 18, name: 'CancelDate', dataType: 'Date', value: cancel_date.strftime("%m/%d/%Y") },
      { id: 17, name: 'StartShip', dataType: 'Date', value: start_ship.strftime("%m/%d/%Y") }
    ]

    defaults[:customFields] = custom_fields
    defaults[:number] = ref_number
    defaults[:customerPO] = customer_po

    defaults[:customer] = { id: sos_customer['id'] }

    update_attribute(:sos_customer_id, sos_customer['id'])

    shipping_address = {
      line1: customer_data_row['ShipAddressLine1'],
      line2: customer_data_row['ShipAddressLine2'],
      line3: customer_data_row['ShipAddressLine3'],
      line4: customer_data_row['ShipAddressLine4'],
      city: customer_data_row['ShipAddressCity'],
      stateProvince: customer_data_row['ShipAddressState'],
      postalCode: customer_data_row['ShipAddressPostalCode'],
      country: customer_data_row['ShipAddressCountry']
    }

    defaults[:shipping][:address] = shipping_address
    defaults[:shipping][:email] = customer_data_row['Send OC to']

    billing_address = {
      line1: customer_data_row['BillAddressLine1'],
      line2: customer_data_row['BillAddressLine2'],
      line3: customer_data_row['BillAddressLine3'],
      line4: customer_data_row['BillAddressLine4'],
      city: customer_data_row['BillAddressCity'],
      stateProvince: customer_data_row['BillAddressState'],
      postalCode: customer_data_row['BillAddressPostalCode'],
      country: customer_data_row['BillAddressCountry']
    }

    defaults[:billing][:address] = billing_address
    defaults[:billing][:email] = customer_data_row['BillingEmail']
    defaults[:customerMessage] = customer_data_row['Shipping Method']
    if customer_data_row['Priority for AOP OCs'].present?
      defaults[:priority] = { id: customer_data_row['Priority for AOP OCs'].split(' ').first.to_i }
    end

    defaults[:terms] = { id: sos_terms['id'] }
    defaults[:channel] = { id: sos_channel['id'] }
    defaults[:location] = { id: sos_location['id'] }
    defaults[:salesRep] = { id: sos_sales_rep['id'] }
    # defaults[:shipping][:address] = sos_customer['shipping']
    # defaults[:billing][:address] = sos_customer['billing']

    defaults[:lines] = WholesaleOrderItem.items_post_data(wholesale_order_items)
    defaults[:discountAmount] = customer_data_row['Customer Discount'].to_f * defaults[:lines].reduce(0) { |sum, line| sum + line[:amount] }

    defaults
  end

  def total
    wholesale_order_items.reduce(0.0) { |sum, item| sum + item.unit_price * item.quantity_ordered }
  end

  def total_by_department
    totals = Hash.new(0)
    wholesale_order_items.each  { |item| totals[item.department] += (item.unit_price * item.quantity_ordered) }
    totals
  end

  def sos_url
    "https://live.sosinventory.com/SalesOrder/IndexView/#{sos_id}"
  end
end

# == Schema Information
#
# Table name: wholesale_orders
#
#  id              :bigint(8)        not null, primary key
#  cancel_date     :datetime
#  customer        :string
#  customer_po     :string
#  location        :string
#  ref_number      :string
#  start_ship      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sos_customer_id :bigint(8)
#  sos_id          :integer
#
