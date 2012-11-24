
module Huuuunt
  module Date
    def self.included(base)
      base.extend Huuuunt::Date
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
