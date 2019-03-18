class Announcement < ActiveRecord::Base

  validates :text_content, presence: true


  belongs_to :application

end