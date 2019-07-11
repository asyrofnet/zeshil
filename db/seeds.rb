# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

## Add default roles
# - Admin
# - Member
# - Official User

role_admin = Role.find_by(name: 'Admin')
if role_admin.nil?
  role_admin = Role.create(name: 'Admin')
end

role_member = Role.find_by(name: 'Member')
if role_member.nil?
  role_member = Role.create(name: 'Member')
end

role_official_user = Role.find_by(name: 'Official Account')
if role_official_user.nil?
  role_official_user = Role.create(name: 'Official Account')
end

Role.helpdesk
Role.bot

# no need to add default user or application, since it can be created using console

# Add default providers
# - twilio
# - infobip
# - nexmo
# - mainapi
Provider.twilio
Provider.infobip
Provider.nexmo
Provider.mainapi