class SpacesOnlyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    # if value is not just spaces
    unless value.gsub(/\A\p{Space}*/, '').strip() != ""
      record.errors[attribute] << (options[:message] || "is just blank spaces.")
    end
  end
end