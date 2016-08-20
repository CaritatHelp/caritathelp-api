class DeviseTokenAuthCreateVolunteers < ActiveRecord::Migration
  def change
    drop_table :volunteers
    create_table(:volunteers) do |t|
      ## Required
      t.string :provider, :null => false, :default => "email"
      t.string :uid, :null => false, :default => ""

      ## Database authenticatable
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, :default => 0, :null => false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email # Only if using reconfirmable

      ## Lockable
      # t.integer  :failed_attempts, :default => 0, :null => false # Only if lock strategy is :failed_attempts
      # t.string   :unlock_token # Only if unlock strategy is :email or :both
      # t.datetime :locked_at

      ## User Info
      t.string :firstname
      t.string :lastname
      t.string :fullname
      t.string :thumb_path
      t.string :nickname
      t.string :image
      t.string :email
      t.string :city
      t.string :gender
      t.date   :birthday
      t.boolean :allow_notifications
      t.boolean :allowgps
      t.decimal :latitude
      t.decimal :longitude

      ## Tokens
      t.json :tokens

      t.timestamps
    end

    add_index :volunteers, :email
    add_index :volunteers, [:uid, :provider],     :unique => true
    add_index :volunteers, :reset_password_token, :unique => true
    # add_index :volunteers, :confirmation_token,   :unique => true
    # add_index :volunteers, :unlock_token,         :unique => true
  end
end
