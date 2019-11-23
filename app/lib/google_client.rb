require 'googleauth'
require 'google/apis/drive_v3'
require 'google/apis/sheets_v4'

# Auths with ENV vars:
# "GOOGLE_CLIENT_ID",
# "GOOGLE_CLIENT_EMAIL",
# "GOOGLE_ACCOUNT_TYPE", 
# "GOOGLE_PRIVATE_KEY"

module GoogleClient
  FILL_LEVEL = '1nvT_f86GTC_9-Kcz-_Q8e_VCgV3ppqXNOPC0xtC_iX8'
  RELEASE_SCHEDULE = '1LIW6Fa4VFpP9pFYrHGy_Hv4RbHB8dRYPdjLfKLLqRQ8'
  WHOLESALE_ORDERS ='1zIIRQOSsmbBqOVuwi96Fxy_KQ1sMBPDmZSXsd1cA7uQ'
  WHOLESALE_ORDER_SHEET = 'API Sales Order Import'
  CUSTOMER_DATA_SHEET = 'Customers Data'

  def self.auth
    Google::Auth::ServiceAccountCredentials.make_creds(scope: 'https://www.googleapis.com/auth/drive')
  end

  def self.drive_service
    drive = Google::Apis::DriveV3::DriveService.new
    drive.authorization = auth
    drive
  end

  def self.drive_files
    self.drive_service.list_files()
  end

  def self.sheet_service
    sheets = Google::Apis::SheetsV4::SheetsService.new
    sheets.authorization = auth
    sheets
  end

  def self.get_sheet(id, range = 'Sheet1')
    sheet_service.get_spreadsheet_values(id, range)
  end

  def self.sheet_values(id, range = 'Sheet1')
    values = get_sheet(id, range).values
    headers = values.shift
    rows = values.map do |row|
      lookup_row = {}
      headers.each_with_index do |header, i|
        lookup_row[header] = row[i]
      end
      lookup_row
    end
  end
end
