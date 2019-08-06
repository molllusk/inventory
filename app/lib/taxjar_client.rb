class TaxjarClient
  def self.connection
    Taxjar::Client.new(api_key: ENV['TAXJAR_TOKEN'])
  end
end
