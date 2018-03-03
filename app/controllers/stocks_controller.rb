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
                             'must not be empty or greater than 15 characters')
    end
    if @stock_form[:start_date] >= @stock_form[:end_date]
      @stock_form.errors.add(:start_date, 'must be less than the end date')
    end
    # TODO: Finish this code here and in config/initializers/stocks.rb
    # if Stocks.invalid_symbol?(@stock_form[:stock_symbol])
    #   @stock_form.errors.add(:stock_symbol, 'is not a valid stock ticker')
    # end
  end

  def query_stocks
    # analyze the stocks for the best time to buy and sell your stock
    @profit, @profit_start, @profit_end = Stocks.run_analysis(@stock_data)
    @starting_date_price = @stock_data.price_at(@profit_start)
    @ending_date_price = @stock_data.price_at(@profit_end)
    puts @profit_end
    # Print a chart with your stocks
    @chart = my_chart
  end

  def forms_errors?
    !@stock_form.errors.messages.empty?
  end

  def init_instance_vars(stocks_params)
    @stock_ticker = stocks_params[:stock_symbol]
    @start_date = stocks_params[:start_date]
    @end_date = stocks_params[:end_date]
    @stock_form = StockForm.new(stocks_params)
  end

  def do_stocks
    stocks = Stocks.do_stocks(@stock_ticker,
                              @start_date,
                              @end_date)
    stocks
  end

  def render_stocks
    @stock_data = do_stocks
    if @stock_data.all_stocks.length < 2
      @stock_form.errors.add(:num_stocks,
                             'there must be at least two stocks in the array')
      render 'index'
    else
      query_stocks
    end
  end

  def create
    # Gather stock data using the form
    init_instance_vars(stocks_params)
    validate_form
    if forms_errors?
      render 'index'
    else
      render_stocks
    end
  end

  def my_chart
    array = []
    @stock_data.all_stocks.each do |stock|
      array << [stock.date, stock.closing] if stock.opening.nil?
      array << [stock.date, stock.opening] unless stock.opening.nil?
    end
    array
  end

  private

  def stocks_params
    params.require(:stock_form).permit(:stock_symbol, :start_date, :end_date)
  end
end
