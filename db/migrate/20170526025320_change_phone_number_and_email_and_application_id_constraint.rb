class ChangePhoneNumberAndEmailAndApplicationIdConstraint < ActiveRecord::Migration[5.1]
  def change
    
    ActiveRecord::Base.transaction do
      apps = Application.all
      # to know if user is duplicate
      apps.each do |app|
        records_array = User.select(:phone_number).where(application_id: app.id).group(:phone_number).having("count(phone_number) > 1")
        records_array.each do |record|
          u = User.find_by(phone_number: record.phone_number, application_id: app.id)
          if !u.nil?
            to_delete = User.where(application_id: app.id).where(phone_number: record.phone_number).where.not(id: u.id)
            puts "from phone number deleted user: " + to_delete.pluck(:id).join(",") + " " + app.app_id
            to_delete.destroy_all
          end
        end

        # no need to run, because it don't alter unique index
        # records_array = User.select(:email).where("phone_number is not null").where(application_id: app.id).group(:email).having("count(email) > 1")
        # records_array.each do |record|
        #   u = User.find_by(email: record.email, application_id: app.id)
        #   if !u.nil?
        #     to_delete = User.where(application_id: app.id).where(email: record.email).where.not(id: u.id)
        #     puts "from email deleted user: " + to_delete.pluck(:id).join(",") + " " + app.app_id
        #     to_delete.destroy_all
        #   end
        # end
      end

      ## no need to run, if application login using phone number, this should be not found anything
      # user_phone_nil = User.where(phone_number: nil)
      # user_phone_nil.each do |upn|
      #   puts "from user_phone_nil: " + upn.id.to_s
      #   upn.update_attribute(:phone_number, '')
      # end

      # user_email_nil = User.where(email: nil)
      # user_email_nil.each do |uen|
      #   puts "from user_email_nil: " + uen.application.app_id + " " + uen.id.to_s + " => " + "#{uen.phone_number.delete('+')}@#{uen.application.app_name.delete(' ').downcase}.id"
      #   uen.update_attribute(:email, "#{uen.phone_number.delete('+')}@#{uen.application.app_name.delete(' ').downcase}.id")
      # end

      # phone number and email should be not null
      # since in postgre it can't be check whether paired column is unique
      # if one column in key constraint is null
      change_column :users, :phone_number, :string, null: false, default: ""
      change_column :users, :email, :string, null: false, default: ""
    end
  end
end
