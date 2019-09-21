# frozen_string_literal: true

module Api
  class Controller < ApplicationController
    before_action :authenticate

    private
    def authenticate
      return true if params[:key] == Digest::SHA1.hexdigest('jammalammadingdong')
      redirect_to :root, flash: { error: 'We were unable to find what you are looking for.' }
    end
  end
end
