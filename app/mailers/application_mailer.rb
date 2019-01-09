# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'joseph@mollusksurfshop.com'
  layout 'mailer'

  def inventory_check(csv)
    attachments["Inventory_check_#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}.csv"] = { mime_type: 'text/csv', content: csv }
    mail to: 'joseph@mollusksurfshop.com,arvelhernandez@gmail.com', subject: 'Inventory Update Spreadsheet', body: 'See attached for the most recent mismatched inventories'
  end
end
