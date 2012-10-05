require 'mysql_access'

class HuuuuntUtil
  def initialize()
    @mysql = MysqlAccess.new()
  end

  def create_full_matchno(matchno)
    full_matchno = ""
    case matchno.to_s.length
    when 1
      return full_matchno = "000#{matchno}"
    when 2
      return full_matchno = "00#{matchno}"
    when 3
      return full_matchno = "0#{matchno}"
    when 4
      return full_matchno.to_s
    else
      puts "matchno(#{matchno}) length(#{matchno.to_s.length}) error!"
    end
  end

  def create_full_teamno(teamno)
    full_teamno = ""
    case teamno.to_s.length
    when 1
      return full_teamno = "0000#{teamno}"
    when 2
      return full_teamno = "000#{teamno}"
    when 3
      return full_teamno = "00#{teamno}"
    when 4
      return full_teamno = "0#{teamno}"
    when 5
      return full_teamno
    else
      puts "teamno(#{teamno}) length(#{teamno.to_s.length}) error!"
    end
  end

  def create_matchinfono(date, matchno, team1no, team2no)
    "#{date.split('-').join}#{create_full_matchno(matchno)}" +
    "#{create_full_teamno(team1no)}#{create_full_teamno(team2no)}"
  end

  def deal_result_match_name(match_name)
    return match_name.strip
  end

  def deal_result_team_name(team_name)
    team_name_utf8 = Iconv.iconv("UTF-8", "GBK", team_name)[0]
      if team_name_utf8.index('(中)')
        team_name_utf8 =  team_name_utf8.sub(/\(中\)/, '')
      end
    team_name = Iconv.iconv("GBK", "UTF-8", team_name_utf8)[0]
    return team_name.strip
  end

  def new_match_insert_or_get_id(match_name_gbk)
    match_name_utf8 = Iconv.iconv("UTF-8", "GBK", match_name_gbk)
    match_id = @mysql.get_match_id_by_match_name(match_name_utf8)
    if match_id == 0
      puts "match name(#{match_name_gbk}) has not exist! "
      # 如果不存在，则插入数据库
      current_match_id = @mysql.get_max_match_id + 1
      @mysql.insert_match_infos(current_match_id, match_name_utf8, '#000000', 0, 0, 0, 0, 0)
      return current_match_id
    end
    return match_id
  end

  def new_team_insert_or_get_id(team_name_gbk, match_id)
    team_name_utf8 = Iconv.iconv("UTF-8", "GBK", team_name_gbk)[0]
    team_id = @mysql.get_team_id_by_team_name(team_name_utf8)
    if team_id == 0
      puts "team name(#{team_name_gbk}) does not exist! "
      current_team_id = @mysql.get_max_team_id + 1
      @mysql.insert_team_infos(current_team_id, team_name_utf8, match_id)
      return current_team_id
    end
    return team_id
  end

  def new_team_home_away?(home_gbk, away_gbk, match_id, is_utf8)
    new_team_exist = false

    home_utf8 = ''
    away_utf8 = ''
    if is_utf8
      home_utf8 = home_gbk
      away_utf8 = away_gbk
    else
      home_utf8 = Iconv.iconv("UTF-8", "GBK", home_gbk)[0]
      away_utf8 = Iconv.iconv("UTF-8", "GBK", away_gbk)[0]
    end

    if home_gbk==nil || home_gbk.size==0
      return false
    end
    if @mysql.get_team_id_by_team_name(home_utf8) == 0
      puts "team name(#{home_gbk}) does not exist! "
      current_team_id = @mysql.get_max_team_id
      @mysql.insert_team_infos(current_team_id+1, home_utf8, match_id)
      new_team_exist = true
    end
    if away_gbk==nil || away_gbk.size==0
      return false
    end
    if @mysql.get_team_id_by_team_name(away_utf8) == 0
      puts "team name(#{away_gbk}) does not exist! "
      current_team_id = @mysql.get_max_team_id
      @mysql.insert_team_infos(current_team_id+1, away_utf8, match_id)
      new_team_exist = true
    end
    return new_team_exist
  end

  # Example: finrate (0.75)
  def self.calc_rate_result(finrate, goal1, goal2)
    result = (goal1 - goal2) * 4 - (finrate * 4).to_i
    #puts "result = #{result} "
    result = result.to_i
    if result <= -2
      return -2
    elsif result == -1
      return -1
    elsif result == 0
      return 0
    elsif result == 1
      return 1
    elsif result >= 2
      return 2
    end
  end
end
