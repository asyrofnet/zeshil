class Role < ActiveRecord::Base
  validates :name, presence: true

  has_many :user_roles
  has_many :users, through: :user_roles

  def self.official
    return Role.find_or_create_by(name: 'Official Account')
  end

  def self.admin
    return Role.find_or_create_by(name: 'Admin')
  end

  def self.member
    return Role.find_or_create_by(name: 'Member')
  end

  def self.helpdesk
    return Role.find_or_create_by(name: 'Helpdesk')
  end

  def self.bot
      return Role.find_or_create_by(name: 'Bot')
  end

  def self.find_official
    official = Role.where(name: "Official Account").first
    if !official.nil?
      official_id = official.id
    else
      off_id = nil
    end
    return official_id
  end

end