# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'joseph@mollusksurfshop.com'
  layout 'mailer'

  def inventory_report(csv)
    attachments["Inventory_report_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"] = { mime_type: 'text/csv', content: csv }
    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: 'Inventory Report Spreadsheet', body: 'See attached for the most recent inventory report'
  end

  def sku_report(bad_retail_products, bad_wholesale_products)
    body = "See below for the latest products with mismatched SKUs:#{ ('<br /><br /><b>Retail Products:</b><br /><br />' + bad_retail_products.map { |prod| "<a href='https://mollusk.herokuapp.com/#{prod.id}'>#{prod.vend_datum.variant_name}</a><br />" }.join) if bad_retail_products.present? }#{ ('<br /><br /><b>Wholesale Products:</b><br /><br />' + bad_wholesale_products.map { |prod| "<a href='https://mollusk.herokuapp.com/#{prod.id}'>#{prod.vend_datum.variant_name}</a><br />" }.join) if  bad_wholesale_products.present? }"
    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: 'Mismatched SKU Report', body: 'body'
  end
end
