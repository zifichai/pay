module Pay
  module Stripe
    module Billable
      # Handles Billable#customer
      #
      # Returns Stripe::Customer
      def stripe_customer
        if processor_id?
          ::Stripe::Customer.retrieve(processor_id)
        else
          create_stripe_customer
        end
      rescue ::Stripe::StripeError => e
        raise Error, e.message
      end

      def create_setup_intent
        ::Stripe::SetupIntent.create
      end

      # Handles Billable#charge
      #
      # Returns Pay::Charge
      def create_stripe_charge(amount, options={})
        args = {
          amount: amount,
          currency: 'usd',
          customer: customer.id,
          description: customer_name,
        }.merge(options)

        stripe_charge = ::Stripe::Charge.create(args)

        # Save the charge to the db, returns Charge
        Pay::Stripe::Webhooks::ChargeSucceeded.new.create_charge(self, stripe_charge)
      rescue ::Stripe::StripeError => e
        raise Error, e.message
      end

      # Handles Billable#subscribe
      #
      # Returns Pay::Subscription
      def create_stripe_subscription(name, plan, options={})
        opts = {
          expand: ['latest_invoice.payment_intent'],
          items: [ plan: plan ],
          off_session: true,
          trial_from_plan: true
        }.merge(options)
        stripe_sub   = customer.subscriptions.create(opts)
        #subscription = create_subscription(stripe_sub, 'stripe', name, plan)
        subscription = create_subscription(stripe_sub, 'stripe', name, plan, status: stripe_sub.status)

        if subscription.incomplete?
          Pay::Payment.new(stripe_sub.latest_invoice.payment_intent).validate
        end
        subscription
      rescue ::Stripe::StripeError => e
        raise Error, e.message
      end

      # Handles Billable#update_card
      #
      # Returns true if successful
      def update_stripe_card(payment_method_id)
        customer = stripe_customer

        return true if payment_method_id == customer.invoice_settings.default_payment_method

        payment_method = ::Stripe::PaymentMethod.attach(payment_method_id, customer: customer.id)
        ::Stripe::Customer.update(customer.id, invoice_settings: { default_payment_method: payment_method_id })

        update_stripe_card_on_file(payment_method.card)
        true
      rescue ::Stripe::StripeError => e
        raise Error, e.message
      end

      def update_stripe_email!
        customer = stripe_customer
        customer.email = email
        customer.description = customer_name
        customer.save
      end

      def stripe_subscription(subscription_id, options={})
        ::Stripe::Subscription.retrieve(options.merge(id: subscription_id))
      end

      def stripe_invoice!
        return unless processor_id?
        ::Stripe::Invoice.create(customer: processor_id).pay
      end

      def stripe_upcoming_invoice
        ::Stripe::Invoice.upcoming(customer: processor_id)
      end

      # Used by webhooks when the customer or source changes
      def sync_card_from_stripe
        stripe_cust = stripe_customer
        default_source_id = stripe_cust.default_source

        if default_source_id.present?
          card = stripe_customer.sources.data.find{ |s| s.id == default_source_id }
          update(
            card_type:      card.brand,
            card_last4:     card.last4,
            card_exp_month: card.exp_month,
            card_exp_year:  card.exp_year
          )

        # Customer has no default payment source
        else
          update(card_type: nil, card_last4: nil)
        end
      end

      private

      def create_stripe_customer
        customer = ::Stripe::Customer.create(email: email, description: customer_name)
        update(processor: 'stripe', processor_id: customer.id)

        # Update the user's card on file if a token was passed in
        if card_token.present?
          ::Stripe::PaymentMethod.attach(card_token, { customer: customer.id })
          customer.invoice_settings.default_payment_method = card_token
          customer.save

          update_stripe_card_on_file ::Stripe::PaymentMethod.retrieve(card_token).card
        end

        customer
      end

      def stripe_trial_end_date(stripe_sub)
        stripe_sub.trial_end.present? ? Time.at(stripe_sub.trial_end) : nil
      end

      # Save the card to the database as the user's current card
      def update_stripe_card_on_file(card)
        update!(
          card_type:      card.brand.capitalize,
          card_last4:     card.last4,
          card_exp_month: card.exp_month,
          card_exp_year:  card.exp_year
        )

        self.card_token = nil
      end
    end
  end
end
