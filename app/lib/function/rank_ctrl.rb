# encoding: utf-8
# 赛程数据导入程序

require 'rubygems'
require 'mysql/rank'

require 'util/date_tool'
require 'util/data_file'
require 'util/rank_data'
require 'util/common'

class RankCtrl

  include Huuuunt::DateTool
  include Huuuunt::DataFile
  include Huuuunt::Common
  include Huuuunt::RankData

  def self.calc_base(args)
    flag, season, match_set = args_analyze(args)
    return unless flag
    #puts "#{season} #{match_set.join(',')}"
    calculate_rank_base(season, match_set)
  end

  def self.calc_history(args)
    flag, season, match_set = args_analyze(args)
    return unless flag
    #puts "#{season} #{match_set.join(',')}"
    calculate_rank_history(season, match_set)
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
  # Huuuunt rank preprocess 2007 1 2 3
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