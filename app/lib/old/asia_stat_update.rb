class AsiaStatUpdate

  STAT_COUNT = 3      # 需要纳入统计的连续输赢场次超过的场次

  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
  end

  def close
    @mysql.close
  end

  def delete_today_stat
    date_str = Time.now.strftime("%Y-%m-%d")
    @mysql.truncate_asia_stat_data_by_date(date_str)
  end

  # match_set: 联赛集
  # match_year: 赛季
  # company: 赔率公司
  def do_update(match_set, match_year, company)
    stat_data = {}
    # 依次处理每个联赛，match_year和联赛对应，如英超对应2008-2009，巴西甲对应2008
    match_set.each do |match_no|
      puts "match = #{match_no}"
      match_no = match_no.to_i
      # 获取每个联赛指定赛季的球队集，并依次处理
      team_set = @mysql.get_teams_by_match_year(match_no, match_year)

      # 计算每支球队的统计赛事的起始日期和结束日期
      start_date = ''
      end_date = ''
      if match_year.length == 4
        start_date = "#{match_year}-01-01"
        end_date = "#{match_year}-12-31"
      else
        start_date, end_date = match_year.split('-')
        start_date = start_date + "-07-01"
        end_date = end_date + "-06-30"
      end
      puts "start_date = #{start_date}, end_date = #{end_date}"

      team_set.each do |team_no|
        #puts "team = #{team_no}"
        team_no = team_no[0].to_i
        # 获取指定球队在指定联赛中，指定日期范围内的赛事数据，按照日期倒序排列
        asia_results = @mysql.get_asia_history_by_year_match_team(company, start_date, end_date, match_no, team_no, 'desc')
        #puts "asia_results.num_rows = #{asia_results.num_rows}"

        start_zero_count = 0    # 用于开始的赛事都是平手的情况
        count = 0
        match_list = []
        start_res = 0
        
        asia_results.each do |result|
          id = result[0].to_i
          team1no = result[4].to_i
          res = result[10].to_i

          # 如果开始的赛事都是平手
          if res == 0 and count == 0
            start_zero_count += 1
            match_list << id
            puts "start zero - #{match_no},#{team_no}"
            next
          end

          team_no_res = 0
          if team1no == team_no
            team_no_res = res
          else
            team_no_res = -res
          end

          count += 1

          if count == 1
            match_list << id
            start_res = team_no_res
          else
            if team_no_res * start_res >= 0
              match_list << id
            else
              if (count+start_zero_count) > STAT_COUNT
                #puts "#{match_no}, #{team_no} - (#{match_list.join(',')})"
                stat_data["#{match_no},#{team_no},#{count-1+start_zero_count},#{start_res}"] = match_list
              end
              count = 0   # 为当前球队赛事循环结束后的处理做准备
              break
            end
          end
        end # asia_results by team
        # 如果联赛刚开始，很可能连续几场的输赢盘都是相同的，则在此处理
        if (count+start_zero_count) >= STAT_COUNT
          #puts "#{match_no}, #{team_no} - (#{match_list.join(',')})"
          stat_data["#{match_no},#{team_no},#{count+start_zero_count},#{start_res}"] = match_list
          count = 0
        end
        #break   # team
      end # team_set
      #break # match
    end # match_set

    date_str = Time.now.strftime("%Y-%m-%d")

    stat_data.each_key do |key|
      match_no, team_no, count, result = key.split(',')
      puts "#{match_no},#{team_no},#{count},#{result} - (#{stat_data[key].join(',')})"
      @mysql.insert_asia_stat_data_type_one(date_str, match_no, team_no, count, result, stat_data[key].join(','))
    end

  end
end
