# Computes Stocks
class StocksController < ApplicationController
  def index
    @stock_form = StockForm.new
  end

  def neg_date_range(start_d, end_d)
    Date.parse(start_d) > Date.parse(end_d)
  end

  def validate_form
    if @stock_form[:stock_symbol].length.zero? ||
       @stock_form[:stock_symbol].length > 15
      @stock_form.errors.add(:stock_symbol,
                             'must not be empty or greater than 4 characters')
    end
    if @stock_form[:start_date] >= @stock_form[:end_date]
      @stock_form.errors.add(:start_date, 'must be less than the end date')
    end
  end

  def query_stocks
    @stock_data = Stocks.do_stocks(stocks_params[:stock_symbol],
                                   stocks_params[:start_date],
                                   stocks_params[:end_date])

    # analyze the stocks for the best time to buy and sell your stock
    @profit, @profit_start, @profit_end = Stocks.run_analysis(@stock_data)

    # Print a chart with your stocks
    @chart = my_chart
  end

  def forms_errors?
    !@stock_form.errors.messages.empty?
  end

  def create
    # Gather stock data using the form
    @stock_form = StockForm.new(stocks_params)
    validate_form
    # puts @stock_form.errors.messages.inspect
    if forms_errors?
      render 'index'
    else
      @stock_data = Stocks.do_stocks(stocks_params[:stock_symbol],
                                     stocks_params[:start_date],
                                     stocks_params[:end_date])

      # puts @stock_data.all_stocks.inspect
      if @stock_data.all_stocks.length < 2
        @stock_form.errors.add(:num_stocks,
                               'there must be at least two stocks in the array')
        render 'index'
      else
        # analyze the stocks for the best time to buy and sell your stock
        @profit, @profit_start, @profit_end = Stocks.run_analysis(@stock_data)
        @stock_ticker = stocks_params[:stock_symbol]
        @starting_date_price = @stock_data.price_at(@profit_start)
        @ending_date_price = @stock_data.price_at(@profit_end)

        # Print a chart with your stocks
        @chart = my_chart
      end
    end
  end

  def my_chart
    array = []
    @stock_data.all_stocks.each do |stock|
      array << [stock.date, stock.opening]
    end
    array
  end

  private

  def stocks_params
    params.require(:stock_form).permit(:stock_symbol, :start_date, :end_date)
  end
end
