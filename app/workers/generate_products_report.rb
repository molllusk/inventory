# frozen_string_literal: true

class GenerateProductsReport
  include Sidekiq::Worker
  sidekiq_options queue: :reporting, retry: false

  def perform
    csv = Product.inventory_csv
    ApplicationMailer.inventory_report(csv).deliver
  end
end
