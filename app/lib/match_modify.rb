class MatchModify
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
    m_match = @mysql.get_need_modify_match_by_teamno(old_teamno)
    m_match.each do |item|
      id = item[0]
      team1no = item[5].to_i
      team2no = item[6].to_i
      team1no = new_teamno if team1no==old_teamno
      team2no = new_teamno if team2no==old_teamno
      puts "team1no:team2no = #{team1no}:#{team2no}"
      @mysql.update_matches_by_teamno(id, team1no, team2no)
    end
  end
end