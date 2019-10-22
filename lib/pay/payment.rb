module Pay
  class Payment
    attr_reader :payment_intent

    delegate :id, :amount, :client_secret, :status, :confirm, to: :payment_intent

    def self.from_id(id)
      new(::Stripe::PaymentIntent.retrieve(id))
    end

    def initialize(payment_intent)
      @payment_intent = payment_intent
    end

    def requires_payment_method?
      status == "requires_payment_method"
    end

    def requires_action?
      status == "requires_action"
    end

    def canceled?
      status == "canceled"
    end

    def cancelled?
      canceled?
    end

    def succeeded?
      status == "succeeded"
    end

    def validate
      if requires_payment_method?
        raise Pay::InvalidPaymentMethod.new(self)
      elsif requires_action?
        raise Pay::ActionRequired.new(self)
      end
    end
  end
end
