class DailyVendSale < ApplicationRecord
  has_many :vend_sales_receipts, dependent: :destroy
  has_many :vend_sales_receipt_sales, dependent: :destroy
end

# == Schema Information
#
# Table name: daily_vend_sales
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
