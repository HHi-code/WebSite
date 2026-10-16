class CreateCatalogs < ActiveRecord::Migration[8.1]
  def change
    create_table :catalogs do |t|
      t.string :name, null: false
      t.text :description
      t.string :border_color, default: "#8B5CF6", null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
