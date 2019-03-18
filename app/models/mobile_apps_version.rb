class MobileAppsVersion < ActiveRecord::Base
  belongs_to :application

  def as_json(options = {})
    h = super(
      :include => [
      ],

      :except => [:application_id]
    )

    return h
  end
end