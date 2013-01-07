# 赛程数据导入程序

require 'rubygems'
require 'mysql/schedule'

require 'util/date_tool'
require 'util/data_file'
require 'util/schedule_gooooal_data'
require 'util/common'

class ScheduleGooooalCtrl

  include Huuuunt::DateTool
  include Huuuunt::DataFile
  include Huuuunt::ScheduleGooooalData
  include Huuuunt::Common

  SCHEDULEPATH = File.expand_path("../../data/schedule/gooooal/", File.dirname(__FILE__))

  # 默认下载赛程数据到最新日期为止
  # season: 赛季信息，如2010、2010-2011
  # match_set: 赛事id集合，如：1
  # 如果match_id为空，则处理指定season的所有数据

  def self.preprocess(args)
    flag, season, match_set = args_analyze(args)
    return unless flag
    # 验证球队名称数据（赛事名称无需验证）
    preprocess_team(season, match_set, SCHEDULEPATH)
  end

  def self.import(args)
    flag, season, match_set = args_analyze(args)
    return unless flag
    insert_schedule(season, match_set, SCHEDULEPATH)
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
    unless seasons.include?(season)
      puts "输入的赛季数据错误：#{season}"
      return FALSE
    end

    # 验证match_set中的每个match_id是否需要统计
    match_set.each do |match_id|
      unless Match.match_need_stat?(match_id)
        puts "输入的赛事ID无需进行统计：#{match_id}"
        return FALSE
      end
    end

    return TRUE
  end

  # 检查输入参数是否正确
  # schedule-gooooal preprocess 2007 1 2 3
  def self.args_analyze(args)
    # flag用于标识输入参数是否正确
    flag = TRUE

    season = args[0]
    args.shift
    match_set = args

    if season.size != 4       # 2003
      puts "输入参数错误：season = #{season}"
      flag = FALSE
      return flag, nil, nil, nil
    end

    # 如果未输入赛事ID，则默认所有可统计的赛事ID
    if match_set.size == 0
      Match.match_need_stat.each_key do |match_id|
        match_set << match_id
      end
    end

    flag = check_params(season, match_set)

    return flag, season, match_set
  end
end