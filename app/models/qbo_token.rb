class QboToken < ApplicationRecord
  def refresh_if_necessary
    access_token = OAuth2::AccessToken.new(::QB_OAUTH2_CONSUMER, token, {refresh_token: refresh_token})
    if updated_at <= 3600.seconds.ago
      access_token = access_token.refresh!
      update_attributes(token: access_token.token, refresh_token: access_token.refresh_token)
    end
    access_token
  end
end

# == Schema Information
#
# Table name: qbo_tokens
#
#  id            :bigint(8)        not null, primary key
#  refresh_token :string
#  token         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  realm_id      :string
#
