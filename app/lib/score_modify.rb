
class ScoreModify
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
    @mysql.update_scores_by_teamno(old_teamno, new_teamno)
  end
end
