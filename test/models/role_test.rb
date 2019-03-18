require 'test_helper'

class RoleTest < ActiveSupport::TestCase
	setup do
		@role = Role.new(
			name: 'New Role'
		)
  	end

  	test "should be valid" do
    	assert @role.valid?
  	end

	test 'name should be present' do
    	@role.name = "         "
    	assert_not @role.name?
	end

end