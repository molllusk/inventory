class DailyVendSalesController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_sale = DailyVendSale.find(params[:id])
  end

  def sales_tax_csv
    send_data(
      VendSalesTax.csv,
      filename: "Vend_sales_tax_#{1.month.ago.strftime("%B")}.csv",
      type: 'text/csv; charset=utf-8; header=present'
    )
  end
end
