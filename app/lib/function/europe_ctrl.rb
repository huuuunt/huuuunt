# 欧洲赔率数据导入程序

require 'mysql/europe'

require 'util/date_tool'
require 'util/data_file'
require 'util/europe_data'

class EuropeCtrl

  include Huuuunt::DateTool
  include Huuuunt::DataFile
  include Huuuunt::EuropeData
  include Huuuunt::Common

  EUROPEPATH = File.expand_path("../../data/europe/", File.dirname(__FILE__))

  # 默认下载数据到最新日期为止
  def self.download(args)
    date_loop do |date|
      download_europe_data(date, EUROPEPATH)
    end
  end

  def self.preprocess(args)
    date_loop do |date|
      xml_file = data_file_path(date, EUROPEPATH, 'xml')
      return unless File.exist?(xml_file)

      # 验证赛事名称和球队名称是否已经在数据库中存在，否则批量插入新的赛事名称和球队名称
      # 返回插入新数据的个数
      size = preprocess_match_team(xml_file)

      # 为了便于处理新增的赛事名称或球队名称，最好针对每天的数据进行及时处理，累积多天数据再处理可能不合适
      return if size > 0
    end
  end

  def self.resultcheck(args)
    date_loop do |date|
      xml_file = data_file_path(date, EUROPEPATH, 'xml')
      return unless File.exist?(xml_file)

      # 验证要插入的赔率数据在赛果数据中已经存在
      return unless all_europe_in_result?(date, xml_file)
    end
  end

  def self.update(args)
    date_loop do |date|
      xml_file = data_file_path(date, EUROPEPATH, 'xml')
      return unless File.exist?(xml_file)

      insert_europe_data(date, xml_file)
    end
  end

  def self.dpu(args)

  end

  def self.date_loop
    # 读取需要更新数据的日期，顺序下载
    start_date = Europe.latest_date("Date")
    #end_date = now_date("Date")
    end_date = Date.parse("2012-09-10")

    while start_date <= end_date
      $logger.debug("Europe date : #{start_date.to_s}")
      yield start_date
      start_date = start_date.succ
    end
  end
end