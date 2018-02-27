class AddStocksymbolToStocks < ActiveRecord::Migration[5.1]
  def change
  	add_column :stock_forms, :stock_symbol, :text
  	add_column :stock_forms, :start_date, :date
  	add_column :stock_forms, :end_date, :date
  end
end
