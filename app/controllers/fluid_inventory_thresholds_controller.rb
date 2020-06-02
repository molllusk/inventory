# frozen_string_literal: true

class FluidInventoryThresholdsController < ApplicationController
  before_action :logged_in_user

  def index
    @inventory_thresholds = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL).sort_by { |row| row['Category'] }
  end
end
