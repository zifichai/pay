class AddStatusToSubscriptions < ActiveRecord::Migration[5.2]
  def change
    add_column :pay_subscriptions, :status, :string
  end
end
