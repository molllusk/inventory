# frozen_string_literal: true

class Testerington
  include Sidekiq::Worker
  sidekiq_options queue: :orders, retry: false

  def perform
    puts "I DID IT!"
  end
end
