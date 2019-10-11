class DailyOrder < ApplicationRecord
  has_many :orders, dependent: :destroy
  
end
