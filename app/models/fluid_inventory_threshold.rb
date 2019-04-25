# == Schema Information
#
# Table name: fluid_inventory_thresholds
#
#  id           :bigint(8)        not null, primary key
#  product_type :bigint(8)
#  threshold    :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class FluidInventoryThreshold < ApplicationRecord
  enum product_type: {
    "Art" => 1,
    "Bags" => 2,
    "Body Surfing" => 3,
    "Books" => 4,
    "Fins" => 5,
    "Gift Card" => 6,
    "Kids Hats" => 7,
    "Kids Shirts" => 8,
    "Kids Sweatshirt" => 9,
    "Kids Sweatshirts" => 10,
    "Kids Swimwear" => 11,
    "Kids Tees" => 12,
    "Mens Boardshorts" => 13,
    "Mens Hats" => 14,
    "Mens Jackets" => 15,
    "Mens Pants" => 16,
    "Mens Shirts" => 17,
    "Mens Shoes" => 18,
    "Mens Shorts" => 19,
    "Mens Sweaters" => 20,
    "Mens Sweatshirts" => 21,
    "Mens Tees" => 22,
    "Mens Wetsuits" => 23,
    "Movies" => 24,
    "Music" => 25,
    "Poster" => 26,
    "Shipping" => 27,
    "Silver Lake Surfboards" => 28,
    "Skateboard" => 29,
    "Snowboard" => 30,
    "Soft Top" => 31,
    "Sunglasses" => 32,
    "Sunscreen" => 33,
    "Surfboard" => 34,
    "Surfing Accessories" => 35,
    "Towels & Blankets" => 36,
    "Towels and Blankets" => 37,
    "Unisex Accessories" => 38,
    "Used Surfboard" => 39,
    "Venice Surfboard" => 40,
    "Womens Bottoms" => 41,
    "Womens Dresses" => 42,
    "Womens Hats" => 43,
    "Womens Jackets" => 44,
    "Womens Shirts" => 45,
    "Womens Shoes" => 46,
    "Womens Sweatshirts" => 47,
    "Womens Swimwear" => 48,
    "Womens Tanks" => 49,
    "Womens Tees" => 50,
    "Womens Wetsuits" => 51
  }
end
