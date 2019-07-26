class Api::V1::Contacts::FavoritesController < ProtectedController
  before_action :authorize_user

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/contacts/favorites List of favourite contacts
  # @apiDescription show all favorited contact
  # @apiName ListFav
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # =end
  def index
    begin
      contacts = nil
      ActiveRecord::Base.transaction do
        contact_id = @current_user.contacts.where(is_favored: true).pluck(:contact_id)
        contacts = User.where("id IN (?)", contact_id).order(fullname: :asc)

        contacts = contacts.as_json({:show_profile => true})

        favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
        contacts = contacts.map do |e|
          e.merge!('is_favored' => favored_status.to_h[ e["id"] ], 'is_contact' => true )
        end

      end

      render json: {
        data: contacts
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {get} /api/v1/contacts/favorites/:id Show Single Favourite Contact
  # @apiDescription where id is contact user id
  # @apiName ShowFav
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} id Contact id
  # =end
  def show
    begin
      contact_to_show = nil
      ActiveRecord::Base.transaction do
        contact_to_show = User.find(params[:id])

        if contact_to_show.nil?
          raise StandardError.new("User is not found.")
        else
          contact = Contact.find_by(user_id: @current_user.id, contact_id: contact_to_show.id)

          if contact.nil?
            raise StandardError.new("This user is not in your contact. Please add before mark it as favourites.")
          end

          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          is_favored = favored_status.to_h[ contact_to_show.id ]
          contact_to_show = contact_to_show.as_json({:show_profile => true}).merge!('is_favored' =>  is_favored, 'is_contact' => true)
        end
      end

      render json: {
        data: contact_to_show
      }
    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {post} /api/v1/contacts/favorites Add Contact as Favourite
  # @apiDescription Mark contact as favourite
  # @apiName AddFav
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} user_id Contact id to be added as favourite
  # =end
  def create
    begin
      contact_candidate = nil
      ActiveRecord::Base.transaction do
        contact_candidate = User.find_by(id: params[:user_id])

        if contact_candidate.nil?
          raise StandardError.new("User is not found.")
        else
          contact = Contact.find_by(user_id: @current_user.id, contact_id: contact_candidate.id)

          if contact.nil?
            raise StandardError.new("This user is not in your contact. Please add before mark it as favourites.")
          else
            contact.update_attribute(:is_favored, true)
          end

          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          is_favored = favored_status.to_h[ contact_candidate.id ]
          contact_candidate = contact_candidate.as_json({:show_profile => true}).merge!('is_favored' =>  is_favored, 'is_contact' => true)
        end
      end

      render json: {
        data: contact_candidate
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end

  # =begin
  # @apiVersion 1.0.0
  # @api {delete} /api/v1/contacts/favorites/:id Remove Contact from Favourite
  # @apiDescription where id is contact user id
  # @apiName DeleteFav
  # @apiGroup Contact
  #
  # @apiParam {String} access_token User access token
  # @apiParam {Number} id Contact id to be deleted from favourites
  # =end
  def destroy
    begin
      unfavorited_candidate = nil
      ActiveRecord::Base.transaction do
        unfavorited_candidate = User.find_by(id: params[:id])

        if unfavorited_candidate.nil?
          raise StandardError.new("User is not found.")
        else
          contact = Contact.find_by(user_id: @current_user.id, contact_id: unfavorited_candidate.id)

          if contact.nil?
            raise StandardError.new("This user is not in your contact. Please add before mark it as favourites.")
          else
            contact.update_attribute(:is_favored, false)
          end

          favored_status = @current_user.contacts.pluck(:contact_id, :is_favored)
          is_favored = favored_status.to_h[ unfavorited_candidate.id ]
          unfavorited_candidate = unfavorited_candidate.as_json({:show_profile => true}).merge!('is_favored' =>  is_favored, 'is_contact' => true)
        end
      end

      render json: {
        data: unfavorited_candidate
      }

    rescue ActiveRecord::RecordInvalid => e
      msg = ""
      e.record.errors.map do |k, v|
        key = k.to_s.humanize
        msg = msg + "#{key} #{v}, "
      end

      msg = msg.chomp(", ") + "."
      render json: {
        error: {
          message: msg
        }
      }, status: 422 and return

    rescue => e
      render json: {
        error: {
          message: e.message
        }
      }, status: 422 and return
    end
  end
end