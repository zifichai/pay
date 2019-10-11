require 'test_helper'

class Pay::Billable::SyncEmail::Test < ActiveSupport::TestCase
  test 'email sync' do
    billable = User.create(email: "test@test.com")
    assert billable.should_sync_email_with_processor?
  end

  test 'email sync should be ignored for billable that delegates email' do
    billable = Team.create(name: "Team 1")
    refute billable.should_sync_email_with_processor?
  end
end
