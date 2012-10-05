

class Result2Matches
  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
  end

  def close
    @mysql.close
  end

  def do_update(match_year, match_set, start_date, end_date)
    match_set.each do |match_id|
      puts "Deal match #{match_id}"
      # 从数据库中查找指定赛事、指定日期范围的比赛结果数据
      result_arr = @mysql.get_results_by_matchno_daterange(match_id, start_date, end_date)
      puts "result_arr.num_rows = #{result_arr.num_rows}"
      # 在matches表中查找是否存在同样的数据,同样的数据指相同的赛事、主客球队
      result_arr.each do |result|
        matchdt = result[0]
        matchno = result[1]
        team1no = result[2]
        team2no = result[3]
        halfgoal1 = result[4]
        halfgoal2 = result[5]
        goal1 = result[6]
        goal2 = result[7]

        #puts "#{matchdt}: #{matchno}, #{team1no}:#{team2no}"

        match_arr = @mysql.get_special_matches(match_year, matchno, team1no, team2no)
        if match_arr.num_rows==0
          puts "#{matchdt}: #{matchno}, #{team1no}:#{team2no} is not exist!"
        elsif match_arr.num_rows==1
          #puts "#{matchdt}: #{matchno}, #{team1no}:#{team2no} exist!"
          match_arr.each do |item|
            id = item[0]
            flag = item[1].to_i
            # 更新比赛结果数据flag +1，更新赔率数据flag +2
            if flag==0
              @mysql.update_special_matches(id, matchdt, halfgoal1, halfgoal2, goal1, goal2, flag+1)
            end
          end
        elsif match_arr.num_rows>1
          #puts "#{matchdt}: #{matchno}, #{team1no}:#{team2no} has #{match_arr.num_rows} items!"
          match_arr.each do |item|
            id = item[0]
            flag = item[1].to_i
            if flag==0
              @mysql.update_special_matches(id, matchdt, halfgoal1, halfgoal2, goal1, goal2, flag+1)
              break
            end
          end
        end
        @mysql.commit
      end
    end
  end
end
