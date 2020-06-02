# frozen_string_literal: true

class SosToken < ApplicationRecord
end

# == Schema Information
#
# Table name: sos_tokens
#
#  id            :bigint(8)        not null, primary key
#  access_token  :text
#  expires_in    :integer
#  refresh_token :text
#  token_type    :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
