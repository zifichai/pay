require 'test_helper'

class Pay::Subscription::BraintreeTest < ActiveSupport::TestCase
  setup do
    @billable = User.new email: "test@example.com"
    @billable.processor = 'braintree'
    @billable.card_token = 'fake-valid-visa-nonce'
  end

  test 'cancel' do
    @billable.subscribe(trial_duration: 0)
    @subscription = @billable.subscription
    @subscription.cancel
    assert_equal @subscription.ends_at, @subscription.processor_subscription.billing_period_end_date
    assert_equal 'canceled', @subscription.status
  end

  test 'cancel_now!' do
    @billable.subscribe(trial_duration: 0)
    @subscription = @billable.subscription
    @subscription.cancel_now!
    assert @subscription.ends_at <= Time.zone.now
    assert_equal 'canceled', @subscription.status
  end

  test 'resume on grace period' do
    @billable.subscribe(trial_duration: 14)
    @subscription = @billable.subscription
    @subscription.cancel
    assert_equal @subscription.ends_at, @subscription.trial_ends_at

    @subscription.resume
    assert_nil @subscription.ends_at
    assert_equal 'active', @subscription.status
  end

  test 'processor subscription' do
    @billable.subscribe(trial_duration: 0)
    assert_equal @billable.subscription.processor_subscription.class, Braintree::Subscription
    assert_equal 'active', @billable.subscription.status
  end

  test 'can swap plans' do
    @billable.subscribe(plan: 'default', trial_duration: 0)
    @billable.subscription.swap('big')

    assert_equal 'big', @billable.subscription.processor_subscription.plan_id
    assert_equal 'active', @billable.subscription.status
  end

  test 'can swap plans between frequencies' do
    @billable.subscribe(plan: 'default', trial_duration: 0)
    @billable.subscription.swap('yearly')

    assert_equal 'yearly', @billable.subscription.processor_subscription.plan_id
    assert_equal 'active', @billable.subscription.status
  end
end
