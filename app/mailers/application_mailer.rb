# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'joseph@mollusksurfshop.com'
  layout 'mailer'

  def inventory_check(csv)
    attachments['.csv'] = {mime_type: 'text/csv', content: csv}
    mail to: 'arvelhernandez@gmail.com', subject: 'Inventory Update Spreadsheet', body: 'See attached for the most recent mismatched inventories'
  end
end
