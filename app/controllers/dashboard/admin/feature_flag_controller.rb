class Dashboard::Admin::FeatureFlagController < AdminController
  before_action :authorize_admin

  def index
    begin
      @application = ::Application.find(@current_admin.application.id)
      @features = @application.features
      @users = @application.users.order(created_at: :desc)

      @path_segments = request.fullpath.split("/")
      
      render "index"
    rescue => e
      flash[:notice] = e.message
      redirect_to '/dashboard/_admin/home'
    end
  end

  def create
    begin
      if params[:target_user_id] == "" || params[:target_user_id].nil?
        raise InputError.new("target_user_id can't be empty.")
      end

      if params[:feature_action] == "" || params[:feature_action].nil? 
        raise InputError.new("Action and can't be empty.")
      end

      string_target_user_id = params[:target_user_id]
      target_user_ids = string_target_user_id.split(",") # Split params target_user_id and convert it to array

      if !target_user_ids.is_a?(Array)
        raise InputError.new("Target user id must be an array of user id.")
      end

      user_params = params.permit!
      features = user_params[:features]
      
      if params[:feature_action] == "add"
        ActiveRecord::Base.transaction do
          new_features = Array.new

          # Looping to get all users target
          target_user_ids.each do |target_user_id|
            # Get feature flag already exist in target_user_id
            feature_already_exist = UserFeature.where(user_id: target_user_id).pluck(:feature_id).to_a
            feature_to_be_added = features - feature_already_exist

            # Looping to get feature_to_be_added
            feature_to_be_added.each do |fid|
              # Ensure that feature_id is nil in target_user_id
              if UserFeature.find_by(user_id: target_user_id, feature_id: fid).nil?
                new_features.push({:user_id => target_user_id, :feature_id => fid})
              end
            end
          end

          # Added new user_features
          UserFeature.create(new_features)
        end
        flash[:success] = "Success add new features."        
      elsif params[:feature_action] == "delete"
        ActiveRecord::Base.transaction do
          # Looping to get all users target
          target_user_ids.each do |target_user_id|
            # Looping to get delete feature
            features.each do |fid|
              user_feature = UserFeature.find_by(user_id: target_user_id, feature_id: fid)
              # Ensure that feature_id is not nil
              if !user_feature.nil?
                user_feature.destroy
              end
            end
          end
        end
        flash[:success] = "Success delete features."
      end

      redirect_to "/dashboard/admin/feature_flag" and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/admin/feature_flag"
    end
  end

  def show_users
    begin
      feature_id = params[:feature_id]

      if feature_id.nil?
        # If feature_id nil then show users that haven't active feature flag

        # First get all feature
        features = Feature.all.where(application_id: @current_admin.application.id).pluck(:id)
        # Get all user 
        all_user = User.all.where(application_id: @current_admin.application.id).pluck(:id)
        # Get user that have feature flag
        user_have_feature_flag = UserFeature.where("user_features.feature_id IN (?)", features).pluck(:user_id).to_a
         
        user_ids = all_user - user_have_feature_flag
      else
        # If feature_id not nil then show users that have feature flag
        features = Feature.where("feature_id IN (?)", feature_id).pluck(:id).to_a
        user_ids = UserFeature.where("user_features.feature_id IN (?)", features).pluck(:user_id).to_a
      end

      @users = User.where("id IN (?)", user_ids).where(application_id: @current_admin.application.id).order(created_at: :desc)

      render 'show_users', layout: false and return
    rescue => e
      flash[:notice] = e.message
      redirect_back fallback_location: "/dashboard/admin/feature_flag"
    end
end


end