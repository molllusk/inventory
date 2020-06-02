# frozen_string_literal: true

class VendInventory < ApplicationRecord
  belongs_to :vend_datum

  def location
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end
end

# == Schema Information
#
# Table name: vend_inventories
#
#  id            :bigint(8)        not null, primary key
#  inventory     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  outlet_id     :string
#  vend_datum_id :integer
#
