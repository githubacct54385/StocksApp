class StockForm < ApplicationRecord
	validates :stock_symbol, presence: true, length: { minimum: 4, maximum: 4 }
end
