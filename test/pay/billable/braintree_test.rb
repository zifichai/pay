require 'test_helper'
require 'minitest/mock'

class Pay::Billable::Braintree::Test < ActiveSupport::TestCase
  setup do
    Pay.braintree_gateway = Braintree::Gateway.new(
      environment: :sandbox,
      merchant_id: 'zyfwpztymjqdcc5g',
      public_key: '5r59rrxhn89npc9n',
      private_key: '00f0df79303e1270881e5feda7788927'
    )

    @billable = User.new email: 'test@example.com'
    @billable.processor = 'braintree'
  end

  test 'creating and getting customer' do
    customer = @billable.customer
    assert customer.id.present?
    assert_equal 'test@example.com', customer.email

    # Make sure Braintree retrieves a customer when one exists
    assert_equal @billable.customer, customer
  end

  test 'can store card' do
    @billable.card_token = 'fake-valid-visa-nonce'
    @billable.customer

    assert_equal 'Visa', @billable.card_brand
  end

  test 'fails with invalid cards' do
    @billable.card_token = 'fake-processor-declined-visa-nonce'

    err = assert_raises Pay::Error do
      @billable.customer
    end

    assert_equal 'Do Not Honor', err.message
  end

  test 'can charge card' do
    @billable.card_token = 'fake-valid-visa-nonce'
    result = @billable.charge(2900)
    assert result.success?
    assert_equal 29.00, result.transaction.amount
  end

  test 'can create a subscription' do
    @billable.card_token = 'fake-valid-visa-nonce'
    @billable.subscribe('default', 'default')
    assert @billable.subscribed?
  end

  test 'can update card' do
    @billable.customer # Make sure we have a customer object
    @billable.update_card('fake-valid-discover-nonce')

    assert_equal 'Discover', @billable.card_brand
  end

  test 'can update card for PayPal' do
    skip("The braintree account isn't setup for PayPal")
    @billable.customer # Make sure we have a customer object
    @billable.update_card('fake-paypal-one-time-nonce')

    assert_equal 'PayPal', @billable.card_brand
  end

  test 'can update existing subscription cards' do
    @billable.card_token = 'fake-valid-visa-nonce'
    @billable.customer # Make sure we have a customer object
    @billable.subscribe('default', 'default')

    subscription = @billable.subscriptions.first
    token = subscription.processor_subscription.payment_method_token

    @billable.update_card('fake-valid-discover-nonce')

    subscription.reload
    refute_equal subscription.processor_subscription.payment_method_token, token
  end

  test 'responds to braintree?' do
    assert @billable.braintree?
  end

  test 'responds to paypal? when card brand is PayPal' do
    refute @billable.paypal?
    @billable.card_brand = 'PayPal'
    assert @billable.paypal?
  end
end
