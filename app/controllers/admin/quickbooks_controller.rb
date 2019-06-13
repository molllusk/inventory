module Admin
  class QuickbooksController < Admin::Controller
    def authenticate
      callback = 'https://mollusk.herokuapp.com/admin/quickbooks/oauth_callback'
      token = QB_OAUTH_CONSUMER.get_request_token(:oauth_callback => callback)
      session[:qb_request_token] = token
      redirect_to("https://appcenter.intuit.com/Connect/Begin?oauth_token=#{token.token}") and return
    end

    def oauth_callback
      at = session[:qb_request_token].get_access_token(:oauth_verifier => params[:oauth_verifier])
      token = at.token
      secret = at.secret
      realm_id = params['realmId']
      QboToken.create(token: token, secret: secret, realm_id: realm_id)
    end
  end
end
