class AdminController < ApplicationController
  protect_from_forgery with: :exception

  include AdminSessionHelper
  
  layout "admin"
end
