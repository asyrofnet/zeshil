class Feature < ActiveRecord::Base

  validates :feature_id, presence: true
  validates :feature_name, presence: true
  validates :is_rolled_out, inclusion: { in: [ true, false, "true", "false"] }

  belongs_to :application

  # has_many :user_features
  # has_many :users, through: :user_features

end