class HomeController < ApplicationController

  def index
      render json: {
        message: "Please go to http://sdk.qiscus.com/",
        status: 200
      } and return
  end

end
