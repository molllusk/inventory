module Admin
  class Controller < ApplicationController
    before_action :logged_in_user

    def index; end
  end
end
