task inventory_report: :environment do
  csv = Product.inventory_csv
  ApplicationMailer.inventory_report(csv).deliver
end
