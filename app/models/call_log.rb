class CallLog < ApplicationRecord
  validates :call_event, presence: true
  validates :caller_user_id, presence: true
  validates :callee_user_id, presence: true
  validates :call_room_id, presence: true
  validates :application_id, presence: true
  validates :duration, presence: true, allow_nil: true, allow_blank: false
  validates :connected_at, presence: true, allow_nil: true, allow_blank: false

  enum status: [ :unknown, :missed, :connected ]

  belongs_to :user
  belongs_to :application

  # because caller and calle user id table refer to user table,
  # we cant override the json format (as_json) before defining the FK one by one
  belongs_to :callee, :class_name => :User, :foreign_key => "callee_user_id"
  belongs_to :caller, :class_name => :User, :foreign_key => "caller_user_id"

  def as_json(options={})
    super.except("caller_user_id", "callee_user_id", "created_at", "updated_at").tap do |h|
      h["caller_user"] = caller.as_json
      h["callee_user"] = callee.as_json
      h["created_at"] = created_at.iso8601
      h["updated_at"] = updated_at.iso8601
    end
  end
end
