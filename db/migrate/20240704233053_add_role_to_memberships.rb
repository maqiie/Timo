class AddRoleToMemberships < ActiveRecord::Migration[7.0]
  def change
    add_column :memberships, :role, :string
  end
end
