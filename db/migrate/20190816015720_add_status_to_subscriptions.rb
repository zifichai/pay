class AddStatusToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :pay_subscriptions, :status, :string

    # Any existing subscriptions should be marked as 'active'
    # This won't actually make them active if their ends_at column is expired
    Pay::Subscription.reset_column_information
    Pay::Subscription.update_all(status: :active)
  end
end
