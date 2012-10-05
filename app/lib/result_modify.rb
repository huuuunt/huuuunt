
class ResultModify
  def initialize
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
  end

  def close
    @mysql.close
  end

  def do_modify(team_arr)
    old_teamno = team_arr[0]
    new_teamno = team_arr[1]
    m_res = @mysql.get_need_modify_result_by_teamno(old_teamno)
    m_res.each do |item|
      id = item[0]
      matchdt = item[2]
      matchno = item[3]
      team1no = item[4].to_i
      team2no = item[5].to_i
      match_date = matchdt.split[0]
      team1no = new_teamno if team1no==old_teamno
      team2no = new_teamno if team2no==old_teamno
      matchinfono = @util.create_matchinfono(match_date, matchno, team1no, team2no)
      puts "matchinfono = #{matchinfono}"
      @mysql.update_results_by_teamno(id, matchinfono, team1no, team2no)
    end
  end
end
