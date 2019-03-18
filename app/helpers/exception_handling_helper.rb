module ExceptionHandlingHelper
  # use 400 error The server cannot or will not process the request due to an apparent client error 
  # (e.g., malformed request syntax, too large size, invalid request message framing, or deceptive request routing)
  # 404 not found
  # 422 if request is well-formed but was unable to be followed due to semantic errors

  def record_not_found(error)
    render json: {
      error: {
        message: 'Not Found'
      }
    }, status: 404
  end 

  def parameter_missing(error)
    render json: {
      error: {
        message: error.message
      }
    }, status: 400
  end 

  def invalid_argument(error)
    render json: {
      error: {
        message: error.message
      }
    }, status: 400
  end 

  def invalid_type(error)
    render json: {
      error: {
        message: error.message
      }
    }, status: 400
  end 
end
