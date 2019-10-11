module Pay
  class Payment
    attr_reader :payment_intent

    def self.from_id(id)
      new(::Stripe::PaymentIntent.retrieve(id))
    end

    def initialize(payment_intent)
      @payment_intent = payment_intent
    end

    def id
      payment_intent.id
    end

    def amount
      payment_intent.amount
    end

    def client_secret
      payment_intent.client_secret
    end

    def requires_payment_method?
      payment_intent.status == "requires_payment_method"
    end

    def requires_action?
      payment_intent.status == "requires_action"
    end

    def canceled?
      payment_intent.status == "canceled"
    end

    def cancelled?
      canceled?
    end

    def succeeded?
      payment_intent.status == "succeeded"
    end

    def validate
      if requires_payment_method?
        raise Pay::InvalidPaymentMethod.new(self)
      elsif requires_action?
        raise Pay::ActionRequired.new(self)
      end
    end

    def confirm
      payment_intent.confirm
    end
  end
end
