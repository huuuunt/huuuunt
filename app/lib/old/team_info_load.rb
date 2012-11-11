
require 'excel_access'
require 'mysql_access'

class TeamInfoLoad
  FILEPATH = File.expand_path("../data/base/team.xls")

  def initialize
    @excel = ExcelAccess.new()
    @excel.open_file(FILEPATH)
    @mysql = MysqlAccess.new()
  end

  def is_end?(line)
    @excel.get_value(line, "A") == nil
  end

  def read_all_lines
    line = 2
    until is_end?(line)
      yield line
      line += 1
    end
  end

  def load_team_infos
    # reload table match_infos
    @mysql.truncate_table_team_infos

    read_all_lines do |line|
      team_id = @excel.get_value(line, 'A') || 0
      team_gbk = @excel.get_value(line, 'B') || ''
      match_gbk = @excel.get_value(line, 'C') || ''
      match_id = @excel.get_value(line, 'D') || 0
      team_tn_gbk = @excel.get_value(line, 'E') || ''
      team_en = @excel.get_value(line, 'F') || ''
      team_jp_gbk = @excel.get_value(line, 'G') || ''

      #if match_gbk != nil && match_gbk.length > 0
        #puts "match_gbk = [#{match_gbk}]"
      #  match_name = Iconv.iconv("UTF-8", "GBK", match_gbk)
      #  match_id = @mysql.get_match_id_by_match_name(match_name)
      #end

      #puts "#{match_id}, #{gbk_name_cn}, #{match_color}, #{is_stat}"
      team_cn = ''
      if team_gbk.class != String
        team_gbk = team_gbk.to_i.to_s
      end
      team_cn = Iconv.iconv("UTF-8", "GBK", team_gbk)

      team_tn = ''
      if team_tn_gbk.class != String
        team_tn_gbk = team_tn_gbk.to_i.to_s
      end
      if team_tn_gbk.length > 0
        team_tn = Iconv.iconv("UTF-8", "GBK", team_tn_gbk)
      end

      team_jp = ''
      if team_jp_gbk.class != String
        team_jp_gbk = team_jp_gbk.to_i.to_s
      end
      if team_jp_gbk.length > 0
        team_jp = Iconv.iconv("UTF-8", "GBK", team_jp_gbk)
      end

      @mysql.insert_team_infos(team_id, team_cn, match_id, team_tn, team_en, team_jp)
    end

    @mysql.commit
  end

  def load_team_other_infos
    # reload table match_other_infos
    @mysql.truncate_table_team_other_infos

    read_all_lines do |line|
      team_id = @excel.get_value(line, 'A') || 0
      
      match_gbk = @excel.get_value(line, 'C') || 'NULL'
      match_id = @excel.get_value(line, 'D') || 0

      if match_gbk != nil && match_gbk.length > 0
        #puts "match_gbk = #{match_gbk}"
        match_name = Iconv.iconv("UTF-8", "GBK", match_gbk)
        match_id = @mysql.get_match_id_by_match_name(match_name)
      end

      names_gbk = []
      start_col = 'J'
      until start_col == 'U'
        names_gbk << @excel.get_value(line, start_col)
        start_col.succ!
      end
      names_gbk.compact!
      names_gbk.each do |name_gbk|
        if name_gbk.class != String
          name_gbk = name_gbk.to_i.to_s
        end
        if name_gbk.size > 0
          name = Iconv.iconv("UTF-8", "GBK", name_gbk)
          @mysql.insert_team_other_infos(team_id, name, match_id)
        end
      end
    end

    @mysql.commit
  end

  def load_team_data
    load_team_infos
    load_team_other_infos
  end

  def close
    @excel.close
    @mysql.close
  end
end
