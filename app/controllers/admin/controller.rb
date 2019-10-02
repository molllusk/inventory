module Admin
  class Controller < ApplicationController
    before_action :logged_in_user
    before_action :admin_required

    def index; end
  end
end
