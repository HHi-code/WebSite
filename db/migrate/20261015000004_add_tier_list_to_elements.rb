class AddTierListToElements < ActiveRecord::Migration[8.1]
  def change
    add_reference :elements, :tier_list, foreign_key: true
    change_column_null :elements, :catalog_id, true
  end
end
