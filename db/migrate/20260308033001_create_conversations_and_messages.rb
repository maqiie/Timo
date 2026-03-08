
class CreateConversationsAndMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations do |t|
      t.integer :sender_id,   null: false
      t.integer :recipient_id, null: false
      t.timestamps
    end

    add_index :conversations, [:sender_id, :recipient_id], unique: true
    add_index :conversations, :recipient_id

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer    :user_id,      null: false
      t.text       :content,      null: false
      t.boolean    :read,         default: false
      t.timestamps
    end

    add_index :messages, :user_id
    add_index :messages, [:conversation_id, :created_at]
  end
end