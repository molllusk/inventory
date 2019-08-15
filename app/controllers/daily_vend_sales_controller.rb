class DailyVendSalesController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_sale = DailyVendSale.find(params[:id])
  end

  def sales_tax_csv
    send_data(
      VendSalesTax.csv,
      filename: VendSalesTax.csv_file_name,
      type: 'text/csv; charset=utf-8; header=present'
    )
  end
end
