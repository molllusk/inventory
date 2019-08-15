class ShopifyInventory < ApplicationRecord
  belongs_to :shopify_datum

  enum location: {
    '4500 Irving St' => 1939009,
    'EasyPost' => 7662829621,
    'Jam Warehouse' => 7700054069,
    'Mollusk SF' => 49481991,
    'Mollusk SL' => 7702609973,
    'Mollusk VB' => 7702577205,
    'Postworks' => 18186895445
  }
end

# == Schema Information
#
# Table name: shopify_inventories
#
#  id               :bigint(8)        not null, primary key
#  inventory        :integer
#  location         :bigint(8)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  shopify_datum_id :integer
#
