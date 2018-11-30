module Pay
  module Stripe
    class SubscriptionRenewing
      def call(event)
        object = event.data.object
        subscription = ::Subscription.find_by(stripe_id: object.subscription)

        notify_user(subscription.user, subscription) if subscription.present?
      end

      private

      def notify_user(user, subscription)
        return unless Pay.send_emails

        Pay::UserMailer.subscription_renewing(user, subscription).deliver_later
      end
    end
  end
end
