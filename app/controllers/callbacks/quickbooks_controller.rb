# frozen_string_literal: true

module Callbacks
  class QuickbooksController < Admin::Controller
    def authenticate
      redirect_uri = 'https://mollusk.herokuapp.com/callbacks/quickbooks/oauth_callback'
      grant_url = ::QB_OAUTH2_CONSUMER.auth_code.authorize_url(redirect_uri: redirect_uri, response_type: 'code', state: SecureRandom.hex(12), scope: 'com.intuit.quickbooks.accounting')
      redirect_to grant_url
    end

    def oauth_callback
      return unless params[:state]

      redirect_uri = 'https://mollusk.herokuapp.com/callbacks/quickbooks/oauth_callback'
      if (resp = ::QB_OAUTH2_CONSUMER.auth_code.get_token(params[:code], redirect_uri: redirect_uri))
        QboToken.find_each(&:destroy)
        QboToken.create(token: resp.token, refresh_token: resp.refresh_token, realm_id: params[:realmId])
        flash[:success] = 'Success! QBO Authenticated! Please close this window'
        redirect_to admin_root_path
      end
    end
  end
end
