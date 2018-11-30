require 'test_helper'

class Pay::Stripe::SubscriptionRenewing::Test < ActiveSupport::TestCase
  setup do
    StripeMock.start

    @event = StripeMock.mock_webhook_event('invoice.upcoming')
  end

  teardown do
    StripeMock.stop
  end

  test 'user is notified' do
    Pay::UserMailer.expects(:subscription_renewing)

    Pay::Stripe::SubscriptionRenewing.new.call(@event)
  end
end
