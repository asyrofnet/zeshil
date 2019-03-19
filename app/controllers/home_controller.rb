class HomeController < ApplicationController

  def index
      render json: {
        message: "Kiwari Engine",
        status: 200
      } and return
  end

end
