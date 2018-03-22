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
    attr_reader :stock_symbol, :stocks
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

    # gets max stock price
    def max_price
      if @stocks.first.opening.nil?
        @stocks.map(&:closing).max
      else
        @stocks.map(&:opening).max
      end
    end

    # gets min stock price
    def min_price
      if @stocks.first.opening.nil?
        @stocks.map(&:closing).min
      else
        @stocks.map(&:opening).min
      end
    end

    # gets the opening price for the stock on this date
    def price_at(date)
      found_stock = @stocks.select { |stock| stock.date == date }.first
      return nil if found_stock.nil?
      found_stock.opening unless found_stock.opening.nil?
      found_stock.closing if found_stock.opening.nil?
    end

    def latest_stock_date
      return '1970-01-01' if @stocks.empty?
      @stocks.map(&:date).max
    end

    # def all_stocks
    #  @stocks
    # end

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

  def self.init_profit_analysis_vars(stocks_list)
    @index = 1
    @max_profit = 0
    if stocks_list.first.opening.nil?
      @min_stock_price = stocks_list.first.closing
    else
      @min_stock_price = stocks_list.first.opening
    end
    @start_date = stocks_list.first.date
    @end_date = Date.parse('1970-01-01')
  end

  def self.decreasing_stock_price(opening_price, min_stock_price)
    (opening_price - min_stock_price) < 0
  end

  def self.new_max_profit(curr_max_profit, max_profit, date, curr_date)
    return [max_profit, curr_date] if curr_max_profit.to_i <= max_profit.to_i
    # new max profit, record the end date
    max_profit = curr_max_profit
    end_date = date
    [max_profit, end_date]
  end

  def self.compute_profit(stock)
    curr_stock = stock
    if curr_stock.opening.nil?
      curr_max_profit = [0, curr_stock.closing - @min_stock_price].max
    else
      curr_max_profit = [0, curr_stock.opening - @min_stock_price].max
    end
    if curr_stock.opening.nil?
      if decreasing_stock_price(curr_stock.closing, @min_stock_price)
        @start_date = curr_stock.date
      end
      @min_stock_price = [@min_stock_price, curr_stock.closing].min
    else
      if decreasing_stock_price(curr_stock.opening, @min_stock_price)
        @start_date = curr_stock.date
      end
      @min_stock_price = [@min_stock_price, curr_stock.opening].min
    end
    @max_profit, @end_date =
      new_max_profit(curr_max_profit, @max_profit, curr_stock.date, @end_date)
    @index += 1
  end

  def self.run_analysis(stock_data)
    stocks_list = stock_data.stocks
    init_profit_analysis_vars(stocks_list)
    compute_profit(stocks_list[@index]) while @index < stocks_list.length
    [@max_profit.round(2), @start_date, @end_date]
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
    return nil if parsed_data.first.nil?
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
    if !dates.empty? && !opening_values.empty? && !closing_values.empty?
      dates.each_with_index do |_date, index|
        net = compute_net(closing_values[index], opening_values[index], 2)
        stocks.add_stock(
          dates[index], opening_values[index], closing_values[index], net
        )
      end
    elsif dates.empty? == false && closing_values.empty? == false
      dates.each_with_index do |_date, index|
        net = 0
        stocks.add_stock(
          dates[index], nil, closing_values[index], net
        )
      end
    end
    
    stocks
  end

  def self.count_dates(trimmed)
    dates = []
    trimmed.each do |element|
      begin
        dates << Date.parse(element)
      rescue
      end
    end
  end

  def self.trimmed_data_to_stocks_prices(trimmed)
    dates = []
    opening_values = []
    closing_values = []
    dates_parsed = trimmed.select { |x| Date.parse(x) rescue nil }
    if dates_parsed.length * 6 == trimmed.length
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
    elsif dates_parsed.length * 2 == trimmed.length
      trimmed.each_with_index do |element, index|
        if index.even?
          dates << Date.parse(element)
        else
          closing_values << element.to_f
        end
      end
    end
    populate_stock_prices(dates, opening_values, closing_values)
  end

  def self.missing_stock_ticker
    'Missing Stock Ticker'
  end

  def self.gather_data(url)
    # query the raw data
    data = Nokogiri::HTML(RestClient.get(url))

    # trim the data
    trimmed = trim_data(data)

    # if trimmed is nil, then you likely used an incorrect query
    return StockPrices.new(missing_stock_ticker) if trimmed.nil?

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
      result.stocks.each do |stock|
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

  # def self.invalid_symbol?(stock_symbol)
  # end
end
