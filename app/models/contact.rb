class Contact < ActiveRecord::Base
  validates :user_id, presence: true
  validates :contact_id, presence: true
  validate  :different_user

  # Relation info
  belongs_to :user
  belongs_to :contact, :class_name => :User, :foreign_key => "contact_id"

  default_scope { joins(:user)}

  # Hooks
  # Update redis cache after create, update and delete
  # after save hooks will called both when Creating or Updating an Object
  # This should update cache after user removed or added to a chat room
  after_save :update_redis_cache
  after_destroy :update_redis_cache
  default_scope  { where("contacts.user_id != contacts.contact_id")}
  
  # Delete and update redis cache for conversation list to make all data sync after update
  def update_redis_cache
    # for add, update or delete contact, the related changes is only between the user and its contact
    # for instance A has contact B (which mean that B has contact A too),
    # if A delete, update (mark or unmark as favorite) it only changes conversation list for user A and B.
    # It does happen when A add C, it only change conversation list of A and C, since the property needed in 
    # conversation list where come from this table is only is_contact and is_favored flag.
    user_ids = [user_id, contact_id]
    user_ids = user_ids.uniq

    ChatRoomHelper.reset_chat_room_cache_for_users(user_ids)
  end

  def as_json(options = {})
    h = super(
      :include => [
        {
          :contact => {}
        }
      ],

      :except => [:user_id, :contact_id]
    )

    return h
  end

private
  def different_user
    errors.add(:contact_id, "cannot be same as user id") if user_id == contact_id
  end
end