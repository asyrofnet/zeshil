class UserController < ApplicationController
  protect_from_forgery with: :exception

  include UserSessionHelper

  layout "user"
end
