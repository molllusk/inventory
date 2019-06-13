class QboToken < ApplicationRecord
end

# == Schema Information
#
# Table name: qbo_tokens
#
#  id         :bigint(8)        not null, primary key
#  secret     :string
#  token      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  realm_id   :string
#
