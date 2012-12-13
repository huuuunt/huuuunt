
require 'mysql/driver'
require 'util/date_tool'

class Result < ActiveRecord::Base

  include Huuuunt::DateTool
  
  # 获取当前需要更新的赛果数据的开始日期，格式 2012-10-10  
  def self.lastest_date(format)
    latest_datetime = maximum('matchdt').strftime('%Y-%m-%d %H:%M:%S')

    return latest_date_format(latest_datetime, format)
  end

  def self.match_exist?(matchinfono)
    results = where("matchinfono = ?", matchinfono)
    if results.size == 0
      return false
    else
      return true
    end
  end
  
end