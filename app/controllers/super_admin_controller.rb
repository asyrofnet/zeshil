class SuperAdminController < ApplicationController
  protect_from_forgery with: :exception
  
  include SuperAdminSessionHelper

  layout "superadmin"
end
