# encoding: utf-8
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
  include Huuuunt::ScheduleData
  include Huuuunt::Common

  #SCHEDULEPATH = File.expand_path("../../data/schedule/", File.dirname(__FILE__))
  SCHEDULEPATH = File.expand_path("../../data/schedule/", File.dirname(__FILE__))

  # 默认下载赛程数据到最新日期为止
  # season: 赛季信息，如2010、2010-2011
  # match_set: 赛事id集合，如：1
  # 如果match_id为空，则处理指定season的所有数据
  def self.download(args)
    flag, season, type, match_set = args_analyze(args)
    return unless flag
    download_schedule_data(season, match_set, SCHEDULEPATH)
  end

  def self.preprocess(args)
    flag, season, type, match_set = args_analyze(args)
    return unless flag
    # 验证球队名称数据（赛事名称无需验证）
    preprocess_team(season, match_set, SCHEDULEPATH)
  end

  def self.import(args)
#    以下代码似乎存在问题
#    date_loop do |date|
#      csv_file = data_file_path(date, SCHEDULEPATH, 'csv')
#      return unless File.exist?(csv_file)
#
#      insert_new_result(csv_file)
#    end
  end

  # 从赛果数据中更新比赛结果到赛程中
  def self.update(args)
    flag, season, type, match_set = args_analyze(args)
    return unless flag
    update_from_result(season, match_set)
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
      next_year = start_year + 1
      seasons << "#{start_year}-#{next_year}"
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

  def self.args_analyze(args)
    flag = TRUE
    
    season = args[0]
    args.shift
    match_set = args

    type = 0
    if season.size == 4       # 2003
      type = 2
    elsif season.size == 9    # 2003-2004
      type = 1
    end

    if type == 0
      puts "输入参数错误：season = #{season}"
      flag = FALSE
      return flag, nil, nil, nil
    end

    if match_set.size == 0
      # 如果未输入赛事ID，则根据赛季类型自动生成
      Match.match_need_stat.each do |key, value|
        if value['type'] == type
          match_set << key
        end
      end
    else 
      # 如果存在输入赛事ID的参数
      origin_type = Match.match_need_stat[match_set[0].to_i]['type']
      match_set.each do |match_id|
        if Match.match_need_stat[match_id.to_i]
          real_type = Match.match_need_stat[match_id.to_i]['type']
          if origin_type != real_type
            puts "输入参数错误：输入的赛事ID（#{match_id}）不是同一个类型"
            flag = FALSE
            return flag, nil, nil, nil
          end
        else
          puts "输入参数错误：输入的赛事ID（#{match_id}）不是同一个类型"
          flag = FALSE
          return flag, nil, nil, nil
        end
      end
    end

    flag = check_params(season, match_set)
    
    return flag, season, type, match_set
  end
end