# Computes Stocks
class StocksController < ApplicationController
  def index
    @stock_form = StockForm.new
  end

  def create
    @stock_data = Stocks.do_stocks(stocks_params[:stock_symbol],
                                   stocks_params[:start_date],
                                   stocks_params[:end_date])
    # @stock_data
  end

  private

  def stocks_params
    params.require(:stock_form).permit(:stock_symbol, :start_date, :end_date)
  end
end
