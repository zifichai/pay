module Pay
  module Stripe
    module Webhooks

      class PaymentActionRequired
        def call(event)
          # Event is of type "invoice" see:
          # https://stripe.com/docs/api/invoices/object

          user    = event.data.object.customer
          payment = Payment.from_id(event.data.object.payment_intent)

          subscription = Pay.subscription_model.find_by(
            processor: :stripe,
            processor_id: event.data.object.subscription
          )

          notify_user(user, payment, subscription)
        end

        def notify_user(user, payment, subscription)
          if Pay.send_emails
            Pay::UserMailer.payment_action_required(user, payment, subscription).deliver_later
          end
        end
      end

    end
  end
end
