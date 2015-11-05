class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts do |t|
      t.integer :user_id, null: false
      t.integer :u_id, null: false
      t.string :username
      t.string :name
      t.string :secret_token
      t.text :best_time
      t.timestamp :last_calculated_time

      t.timestamps null: false
    end
  end
end
