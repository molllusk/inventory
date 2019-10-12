# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'joseph@mollusksurfshop.com'
  layout 'mailer'

  def inventory_report(csv)
    attachments["Inventory_report_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"] = { mime_type: 'text/csv', content: csv }
    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: 'Inventory Report Spreadsheet', body: 'See attached for the most recent inventory report'
  end

  def sku_report(bad_retail_products, bad_wholesale_products)
    body = "One or more mismatched skus were detected between previously matched Vend and Shopify products:#{ ('<br /><br /><b>Retail Mismatches:</b><br /><ul>' + bad_retail_products.map { |prod| "<li><a href='https://mollusk.herokuapp.com/products/#{prod.id}'>#{prod.vend_datum.variant_name}</a></li>" }.join + '</ul>') if bad_retail_products.present? }#{ ('<br /><br /><b>Wholesale Mismatches:</b><br /><ul>' + bad_wholesale_products.map { |prod| "<li><a href='https://mollusk.herokuapp.com/products/#{prod.id}'>#{prod.vend_datum.variant_name}</a></li>" }.join + '</ul>') if  bad_wholesale_products.present? }"
    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: 'Mismatched SKU Report', content_type: 'text/html', body: body
  end

  def po_pdf(daily_order)
    attachments[daily_order.pdf_filename] = daily_order.to_pdf

    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: "#{daily_order.outlet_name} Inventory Transfers for #{daily_order.date.strftime('%m/%d/%y')}", body: "See attached for PO #{daily_order.display_po} including inventory transfers for #{daily_order.outlet_name} ordered today: #{daily_order.date.strftime('%m/%d/%y')}.<br /><br /><strong>Please email the completed packing slip to:</strong> <a href='mailto:johanna@mollusksurfshop.com'>Johanna@MolluskSurfShop.com</a>.<br /><br />Thank you!"
  end
end
