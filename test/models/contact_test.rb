require 'test_helper'

class ContactTest < ActiveSupport::TestCase
  setup do
    @user1     = users(:user1)
    @user2     = users(:user2)
		@contact  = Contact.new(
                user_id: @user1.id,
                contact_id: @user2.id,
              )
  end

  test "should be valid" do
    	assert @contact.valid?
  	end

  test 'user_id should be present' do
    	@contact.user_id = nil
    	assert_not @contact.valid?
	end

  test 'contact_id should be present' do
    	@contact.contact_id = "         "
    	assert_not @contact.valid?
  end
  
  test 'user_id and contact_id cant be same' do
    @contact.contact_id = @user1.id
    assert_not @contact.valid?
    refute_nil @contact.errors
  end
end