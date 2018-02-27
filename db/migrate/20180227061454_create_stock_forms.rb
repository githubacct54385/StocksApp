class CreateStockForms < ActiveRecord::Migration[5.1]
  def change
    create_table :stock_forms do |t|

      t.timestamps
    end
  end
end
