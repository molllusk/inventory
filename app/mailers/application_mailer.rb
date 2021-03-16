# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'joseph@mollusksurfshop.com'
  layout 'mailer'

  def inventory_report(csv)
    attachments["Product_Inventory_Report_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"] = { mime_type: 'text/csv', content: csv }
    mail to: 'joseph@mollusksurfshop.com, john@mollusksurfshop.com, johanna@mollusksurfshop.com', cc: 'arvelhernandez@gmail.com', subject: 'Inventory Report Spreadsheet', body: 'See attached for the most recent inventory report'
  end

  def otb_report(xls, start_date, end_date)
    subject = "OTB Report - #{start_date.strftime('%m/%d/%Y')}-#{end_date.strftime('%m/%d/%Y')}"
    body = "See attached for the latest OTB report from #{start_date.strftime('%m/%d/%Y')} to #{end_date.strftime('%m/%d/%Y')}."

    attachments["#{subject}.xls"] = { mime_type: 'application/xls; charset=utf-8; header=present', content: xls }
    mail to: 'john@mollusksurfshop.com', cc: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: subject, body: body
  end

  def po(daily_inventory_transfer)
    daily_inventory_transfer.daily_orders.each do |daily_order|
      unless daily_order.orders.blank?
        attachments[daily_order.pdf_filename] = daily_order.to_pdf
        attachments[daily_order.csv_filename] = daily_order.to_csv
      end
    end
    @daily_inventory_transfer = daily_inventory_transfer

    mail to: 'joseph@mollusksurfshop.com, john@mollusksurfshop.com, johanna@mollusksurfshop.com, sfmanager@mollusksurfshop.com, daveo@mollusksurfshop.com, maddie@mollusksurfshop.com, beau@mollusksurfshop.com', cc: 'arvelhernandez@gmail.com', subject: "Mollusk Order #{daily_inventory_transfer.po_id}"
  end

  def barcode_issues(duplicates, deletions)
    @shopify_duplicates = duplicates
    @shopify_deletions = deletions

    mail to: 'joseph@mollusksurfshop.com, arvelhernandez@gmail.com', subject: "Shopify Product Issues #{Time.now.strftime("%F")}"
  end
end
