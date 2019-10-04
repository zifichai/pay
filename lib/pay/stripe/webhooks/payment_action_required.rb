module Pay
  module Stripe
    module Webhooks

      class PaymentActionRequired
        def call(event)
          # Event is of type "invoice" see:
          # https://stripe.com/docs/api/invoices/object
          subscription = Pay.subscription_model.find_by(
            processor: :stripe,
            processor_id: event.data.object.subscription
          )
          notify_user(subscription.owner, subscription) if subscription.present?
        end

        def notify_user(user, subscription, payment_intent_id)
          if Pay.send_emails
            Pay::UserMailer.payment_action_required(user, subscription, payment_intent_id).deliver_later
          end
        end
      end

    end
  end
end
