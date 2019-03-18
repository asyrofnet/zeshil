class Dashboard::SuperAdmin::HomeController < SuperAdminController
  before_action :authorize_super_admin

  # template dashboard/super_admin/home/index
  def index
    @application = ::Application.all.order(created_at: :desc)
    render 'index'
  end

end