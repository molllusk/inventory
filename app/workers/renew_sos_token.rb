# frozen_string_literal: true

class RenewSosToken
  include Sidekiq::Worker
  sidekiq_options queue: :orders, retry: false

  def perform
    SosClient.renew_token
  end
end
