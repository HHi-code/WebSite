class CreateElements < ActiveRecord::Migration[8.1]
  def change
    create_table :elements do |t|
      t.string :title, null: false
      t.text :description
      t.integer :rating, null: false, default: 0
      t.references :catalog, null: false, foreign_key: true

      t.timestamps
    end
  end
end
