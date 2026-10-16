class CreateTierListElements < ActiveRecord::Migration[8.1]
  def change
    create_table :tier_list_elements do |t|
      t.references :tier_list, null: false, foreign_key: true
      t.references :element, null: false, foreign_key: true
      t.string :rank, null: false, default: "unranked"
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :tier_list_elements, [:tier_list_id, :element_id], unique: true
    add_index :tier_list_elements, [:tier_list_id, :rank, :position]
  end
end
