# frozen_string_literal: true

class BarcodeIssuesCheck
  include Sidekiq::Worker

  def perform
    duplicates = ShopifyDuplicate.where(['updated_at > ?', 1.day.ago]).order('updated_at DESC')
    deletions = ShopifyDeletion.where(['updated_at > ?', 1.day.ago]).order('created_at DESC')

    ApplicationMailer.barcode_issues(duplicates, deletions).deliver if duplicates.present? || deletions.present?
  end
end
