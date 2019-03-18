class CustomMenu < ApplicationRecord
  validates :application_id, presence: true
  validates :caption, presence: true
  validates :url, presence: true, url: true

  belongs_to :application
end
