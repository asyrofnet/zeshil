class HomeController < ApplicationController

  def index
      render json: {
        message: "ChatAja Engine",
        status: 200
      } and return
  end

end
