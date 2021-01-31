# frozen_string_literal: true

class VendInventory < ApplicationRecord
  belongs_to :vend_datum

  DEAD_LOCATIONS = ['5e234f4e-8eed-11e0-8e09-4040f540b50a'] # San Francisco

  scope :exclude_dead_locations, -> { where.not(outlet_id: DEAD_LOCATIONS) }

  def self.active_locations
    VendClient::OUTLET_NAMES_BY_ID.values - DEAD_LOCATIONS.map { |outlet_id| VendClient::OUTLET_NAMES_BY_ID[outlet_id] }
  end

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
