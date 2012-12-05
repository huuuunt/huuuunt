
require 'date'

module Huuuunt
  module DateTool
    def self.included(base)
      base.extend Huuuunt::DateTool
    end

    # format: String | Date
    def latest_date_format(latest_datetime, format)
      # 获取最近日期
      latest_date = latest_datetime.to_s.split[0]
      # 获取最近日期的下一个日期
      next_date = Date.parse(latest_date).succ.to_s
      # 基准时间设置
      std_datetime = latest_date + " 08:00:00"

      # 如果最近的日期时间值在当天8点之后，则要取下一天作为起始日期
      if (Time.parse(latest_datetime) - Time.parse(std_datetime)) > 0
        start_date = next_date
      else
        start_date = latest_date
      end

      case format
        when 'String'
          return start_date
        when 'Date'
          return Date.parse(start_date)
        else
          $logger.error("#{format} 不正确！")
        end
    end

    # 获取需要更新数据的最新日期，数据格式支持Date和String类型，2012-10-10
    def now_date(format)
      # 默认每天上午9点后可以更新昨日的赛果数据，而上午9点之前，只能更新前两天的赛果数据
      now = Time.now
      yesterday = now - 60*60*24
      yesterday2 = now - 2*60*60*24

      std_time = "#{now.year}-#{now.month}-#{now.day} 09:00:00"

      if now > Time.parse(std_time)
        end_date = "#{yesterday.year}-#{yesterday.month}-#{yesterday.day}"
      else
        end_date = "#{yesterday2.year}-#{yesterday2.month}-#{yesterday2.day}"
      end

      case format
      when 'String'
        return end_date
      when 'Date'
        return Date.parse(end_date)
      else
        $logger.error("#{format} 不正确！")
      end
    end


  end
end
