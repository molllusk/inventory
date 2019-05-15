class FluidInventoryUpdate < ApplicationRecord
  belongs_to :product
end

# == Schema Information
#
# Table name: fluid_inventory_updates
#
#  id                  :bigint(8)        not null, primary key
#  adjustment          :integer
#  new_retail_qty      :integer
#  new_wholesale_qty   :integer
#  prior_retail_qty    :integer
#  prior_wholesale_qty :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  product_id          :integer
#