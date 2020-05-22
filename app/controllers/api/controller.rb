# frozen_string_literal: true

module Api
  class Controller < ApplicationController
    before_action :authenticate

    private

    # this is silly, but we only have one generic admin level api action for now so whatever
    def authenticate
      return true if params[:key] == Digest::SHA1.hexdigest(ENV['API_KEY_SECRET'])

      redirect_to :root, flash: { error: 'We were unable to find what you are looking for.' }
    end
  end
end
