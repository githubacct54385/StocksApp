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
    # @chart = chart_for_stocks
    # puts @chart
    # puts chart2
    @chart = chart2
  end

  def chart_for_stocks
    chart_text = "line_chart [\n"
    @stock_data.all_stocks.each_with_index do |stock, index|
      add_text = if index == (@stock_data.all_stocks.length - 1)
                   "['#{stock.date}', #{stock.opening}]"
                 else
                   "['#{stock.date}', #{stock.opening}],"
                 end
      chart_text += add_text
    end
    chart_text += "\n]"
  end

  def chart2
    array = []
    @stock_data.all_stocks.each do |stock|
      # puts [ stock.date, stock.opening ]
      array << [stock.date, stock.opening]
    end
    array
  end

  # line_chart [
  #	['2018-01-01', 170],
  #	['2018-01-02', 171]
  # ]
  # end

  # line_chart [
# [2018-02-26, 176.35],[2018-02-23, 173.67],[2018-02-22, 171.8],[2018-02-21, 172.83],[2018-02-20, 172.05],[2018-02-16, 172.36],[2018-02-15, 169.79],[2018-02-14, 163.04],[2018-02-13, 161.95],[2018-02-12, 158.5],[2018-02-09, 157.07],[2018-02-08, 160.29],[2018-02-07, 163.08],[2018-02-06, 154.83],[2018-02-05, 159.1]
# ]

  private

  def stocks_params
    params.require(:stock_form).permit(:stock_symbol, :start_date, :end_date)
  end
end
