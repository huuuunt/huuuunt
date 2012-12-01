# 欧洲赔率数据导入程序

require 'mysql/result'

require 'util/date'
require 'util/data_file'
require 'util/europe_data'

class EuropeCtrl

  include Huuuunt::Date
  include Huuuunt::DataFile

  EUROPEPATH = File.expand_path("../../data/europe/", File.dirname(__FILE__))

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

      # 验证赛事名称是否已经在数据库中存在，否则批量插入新的赛事名称
      match_infos = get_new_match(csv_file)
      insert_new_match_name(match_infos)

      # 验证球队名称是否已经在数据库中存在，否则批量插入新的球队名称
      team_infos = get_new_team(csv_file)
      insert_new_team_name(team_infos)

      # 为了便于处理新增的赛事名称或球队名称，最好针对每天的数据进行及时处理，累积多天数据再处理可能不合适
      if match_infos.size>0 || team_infos.size>0
        return
      end
    end
  end

  def self.update(args)
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

    while start_date <= end_date
      yield start_date
      start_date = start_date.succ
    end
  end
end