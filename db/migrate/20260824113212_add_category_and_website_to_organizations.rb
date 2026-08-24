class AddCategoryAndWebsiteToOrganizations < ActiveRecord::Migration[7.0]
  def change
    add_column :organizations, :category, :string
    add_column :organizations, :website, :string
  end
end
