# 赛程数据导入程序

require 'rubygems'
require 'mysql/schedule'

require 'util/date_tool'
require 'util/data_file'
require 'util/schedule_data'
require 'util/common'

class ScheduleCtrl

  include Huuuunt::DateTool
  include Huuuunt::DataFile
  #include Huuuunt::ScheduleData
  include Huuuunt::Common

  SCHEDULEPATH = File.expand_path("../../data/schedule/", File.dirname(__FILE__))

  # 默认下载赛程数据到最新日期为止
  # season: 赛季信息，如2010、2010-2011
  # match_set: 赛事id集合，如：1
  # 如果match_id为空，则处理指定season的所有数据
  def self.download(args)
    season, match_set = args_analyze(args)
    return unless check_params(season, match_set)
    download_schedule_data(season, match_set, SCHEDULEPATH)
  end

  def self.preprocess(args)
    season, match_set = args_analyze(args)
    return unless check_params(season, match_set)
    # 验证球队名称数据（赛事名称无需验证）
    preprocess_team(season, match_set, SCHEDULEPATH)
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

  def self.check_params(season, match_set)
    # 初始化从2003年开始的season数据用于验证
    start_year = 2003
    end_year = Time.new.year
    seasons = []
    while start_year <= end_year
      seasons << "#{start_year}"
      start_year += 1
    end

    # 验证season
    return FALSE unless seasons.include?(season)

    # 验证match_set中的每个match_id是否需要统计
    match_set.each do |match_id|
      return FALSE unless MatchHelper.match_need_stat?(match_id)
    end

    return TRUE
  end

  def self.args_analyze(args)
    season = args[0]
    args.shift
    match_set = args
    return season, match_set
  end
end