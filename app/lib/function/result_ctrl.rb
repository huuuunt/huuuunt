# 赛果数据导入程序

require 'rubygems'
require 'mysql/result'

require 'util/date_tool'
require 'util/data_file'
require 'util/result_data'
require 'util/common'

class ResultCtrl

  include Huuuunt::DateTool
  include Huuuunt::DataFile
  include Huuuunt::ResultData
  include Huuuunt::Common
  
  RESULTPATH = File.expand_path("../../data/result/", File.dirname(__FILE__))

  # 默认下载赛果数据到最新日期为止
  def self.download(args)
    date_loop do |date|
      download_result_data(date, RESULTPATH)
    end
  end

  def self.preprocess(args)
    # 查看当前需要更新日期的数据文件是否存在，不存在则直接返回
    date_loop do |date|
      csv_file = data_file_path(date, RESULTPATH, 'csv')
      return unless File.exist?(csv_file)

      # 验证赛事名称和球队名称是否已经在数据库中存在，否则批量插入新的赛事名称和球队名称
      # 返回插入新数据的个数
      size = preprocess_match_team(csv_file)

      # 为了便于处理新增的赛事名称或球队名称，最好针对每天的数据进行及时处理，累积多天数据再处理可能不合适
      #exit if size > 0
    end
  end

  def self.import(args)
    date_loop do |date|
      csv_file = data_file_path(date, RESULTPATH, 'csv')
      return unless File.exist?(csv_file)

      insert_new_result(csv_file)
    end
  end

  def self.dpu(args)

  end

  def self.date_loop
    # 读取需要更新数据的日期，顺序下载
    start_date = Result.lastest_date("Date")
    end_date = now_date("Date")

    #start_date = Date.parse("2012-09-16")
    end_date = Date.parse("2011-06-30")

    while start_date <= end_date
      #$logger.debug("Result date : #{start_date.to_s}")
      puts "Result date: #{start_date.to_s}"
      yield start_date
      start_date = start_date.succ
    end
  end
end