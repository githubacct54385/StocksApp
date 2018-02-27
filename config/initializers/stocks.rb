require 'rubygems'
require 'rest-client'
require 'json'
require 'nokogiri'
require 'uri'

# Does Stocks computation
module Stocks
  # Holds an array of opening and
  # closing stock prices with their respective dates
  class StockPrices
    def initialize(stock_symbol, stocks_array = nil)
      @stocks = if stocks_array.nil?
                  []
                else
                  stocks_array
                end
      @stock_symbol = stock_symbol
    end

    def add_stock(date, opening, closing, net)
      new_stock = Stock.new(date, opening, closing, net)
      @stocks << new_stock
    end

    def stock_msg(stock)
      day_of_week = stock.date.strftime('%A')
      "On #{day_of_week}\t #{stock.date}, "\
      "opening: #{stock.opening},"\
      "closing: #{stock.closing},"\
      "net: #{stock.net}"
    end

    def latest_stock_date
      return '1970-01-01' if @stocks.empty?
      @stocks.map(&:date).max
    end

    def all_stocks
      @stocks
    end

    # sorts in descending order
    def sort
      @stocks.sort_by!(&:date)
    end

    def print_stocks_count
      "Printing #{@stocks.length} stocks for #{@stock_symbol}"
    end

    def print
      sort
      @stocks.reverse_each do |stock|
        puts stock_msg(stock)
      end
    end
  end

  # Contains stock date, opening and closing price
  class Stock
    attr_reader :date, :opening, :closing, :net
    def initialize(date, opening, closing, net)
      @date = date
      @opening = opening
      @closing = closing
      @net = net
    end
  end

  # Abstract Custom Error class
  class CustomError < StandardError
    def example
      '$ StockSymbol=aapl '  \
      'StartDate=2018-01-01 EndDate=2018-01-30 ruby <file-name.rb>'
    end
  end

  # Exception for a missing StockSymbol
  class MissingStockSymbolException < CustomError
    def preamble
      'Please include the StockSymbol environment variable'
    end

    def initialize(msg = "#{preamble}\n#{example}")
      super(msg)
    end
  end

  # Exception for a missing Start, End, or both
  class MissingDatesException < CustomError
    def preamble
      'Please include the Start and End environment variables'
    end

    def initialize(msg = "#{preamble}\n#{example}")
      super(msg)
    end
  end

  # Constants
  BASE_URL = 'https://finance.google.com/finance/historical'.freeze

  def self.date_diff(start_date, end_date)
    diff = Date.parse(end_date) - Date.parse(start_date)
    diff.to_s.split('/').first
  end

  def self.init_instance_vars(symbol, start_date, end_date)
    @symbol = symbol
    @start_date = start_date
    @end_date = end_date
  end

  def self.do_stocks(symbol, start_date, end_date)
    init_instance_vars(symbol, start_date, end_date)
    stocks = if date_diff(start_date, end_date).to_i <= 30
               query_one_month_stocks
             else
               query_more_than_month_stocks
             end
    stocks
  end

  def self.finance_url(params)
    "#{BASE_URL}?#{URI.encode_www_form(params)}"
  end

  def self.not_relevant_data(line)
    non_relevant = ['\n', '', 'Date', 'Open', 'High', 'Low', 'Close', 'Volume']
    non_relevant.include? line
  end

  def self.trim_data(data)
    parsed_data = data.css('.elastic').css('.g-unit').css('.g-c').css('.id-histform').css('.gf-table-wrapper').css('.gf-table')
    parsed = parsed_data.first.text.split("\n")
    trimmed = []
    parsed.each do |line|
      next if not_relevant_data(line)
      trimmed << line
    end
    trimmed
  end

  def self.compute_net(closing, opening, rounding)
    (closing - opening).round(rounding)
  end

  def self.populate_stock_prices(dates, opening_values, closing_values)
    stocks = StockPrices.new(@symbol)
    dates.each_with_index do |_date, index|
      net = compute_net(closing_values[index], opening_values[index], 2)
      stocks.add_stock(
        dates[index], opening_values[index], closing_values[index], net
      )
    end
    stocks
  end

  def self.trimmed_data_to_stocks_prices(trimmed)
    dates = []
    opening_values = []
    closing_values = []
    trimmed.each_with_index do |element, index|
      if ((index + 6) % 6).zero?
        dates << Date.parse(element)
      elsif (index + 6) % 6 == 1
        opening_values << element.to_f
      elsif (index + 6) % 6 == 4
        closing_values << element.to_f
      elsif (index + 6) % 6 == 5
        next # skip
      end
    end
    populate_stock_prices(dates, opening_values, closing_values)
end

  def self.gather_data(url)
    # query the raw data
    data = Nokogiri::HTML(RestClient.get(url))

    # trim the data
    trimmed = trim_data(data)

    # place trimmed data into StocksPrices class
    trimmed_data_to_stocks_prices(trimmed)
  end

  # use one query to get all stocks
  def self.query_one_month_stocks
    finance_params = {}
    finance_params[:q] = @symbol
    finance_params[:startdate] = @start_date
    finance_params[:enddate] = @end_date
    api_url = finance_url(finance_params)
    stocks = gather_data(api_url)
    stocks
  end

  def self.query_end_date(start_iterator, end_date)
    if start_iterator + 29 > end_date
      end_date.to_s
    else
      (start_iterator + 29).to_s
    end
  end

  def self.init_finance_params(start_date, end_date)
    finance_params = {}
    finance_params[:q] = @symbol
    finance_params[:startdate] = start_date
    finance_params[:enddate] = query_end_date(start_date, end_date)
    finance_params
  end

  def self.stock_queries
    start_iterator = Date.parse(@start_date)
    end_date = Date.parse(@end_date)
    queries = []
    while start_iterator < end_date
      finance_params = init_finance_params(start_iterator, end_date)
      queries << finance_url(finance_params)
      start_iterator += 30
    end
    queries
  end

  def self.stocks_array_from_results(results)
    stocks = []
    results.each do |result|
      result.all_stocks.each do |stock|
        stocks << stock
      end
    end
    stocks
  end

  # use multiple queries to get all stocks date
  def self.query_more_than_month_stocks
    queries = stock_queries
    results = []
    queries.each do |query|
      results << gather_data(query)
    end
    stocks = stocks_array_from_results(results)
    stock_prices = StockPrices.new(@symbol, stocks)
    stock_prices.sort
    stock_prices
  end
end
