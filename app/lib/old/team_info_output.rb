
require 'excel_access'
require 'mysql_access'

class TeamInfoOutput
  FILEPATH = File.expand_path("../data/base/team.xls")

  TEAM_COLS_NAME = [
    "TeamNo", "TeamName", "MatchName", "MatchNo",
    "TeamNameTn", "TeamNameEn", "TeamNameJp", "", "",
    "TeamName1", "TeamName2", "TeamName3", "TeamName4", "TeamName5",
    "TeamName6", "TeamName7", "TeamName8", "TeamName9", "TeamName10"
  ]

  def initialize
    @excel = ExcelAccess.new()
    @excel.new_file(FILEPATH)
    @mysql = MysqlAccess.new()
  end

  def write_team_column_name
    line = 1
    start_col = "A"

    TEAM_COLS_NAME.each do |col_name|
      @excel.set_value(line, start_col, col_name)
      start_col.succ!
    end
  end

  def output_team_infos
    all_team_infos = @mysql.get_all_team_infos

    row = 1
    all_team_infos.each do |team|
      team_id = team[0]
      team_utf8 = team[1]
      team_tn_utf8 = team[2]
      team_en = team[3]
      team_jp_utf8 = team[4]
      match_id = team[5]
      match_utf8 = team[6]

      team_gbk = Iconv.iconv("GBK", "UTF-8", team_utf8)
      team_tn_gbk = ''
      if team_tn_utf8!=nil && team_tn_utf8.length>0
        team_tn_gbk = Iconv.iconv("GBK", "UTF-8", team_tn_utf8)
      end
      team_jp_gbk = ''
      if team_jp_utf8!=nil && team_jp_utf8.length>0
        team_jp_gbk = Iconv.iconv("GBK", "UTF-8", team_jp_utf8)
      end
      match_gbk = Iconv.iconv("GBK", "UTF-8", match_utf8)
      #puts "#{team_id}, #{team_gbk}, #{match_id}, #{match_gbk}"
      row += 1
      @excel.set_value(row, "A", team_id)
      @excel.set_value(row, "B", team_gbk)
      @excel.set_value(row, "C", match_gbk)
      @excel.set_value(row, "D", match_id)
      @excel.set_value(row, "E", team_tn_gbk)
      @excel.set_value(row, "F", team_en)
      @excel.set_value(row, "G", team_jp_gbk)
    end
  end

  def output_team_other_infos
    all_team_other_infos = @mysql.get_all_team_other_infos

    current_col = 'J'
    old_team_id = 0

    all_team_other_infos.each_hash do |team|
      team_id = team['team_id']
      name_utf8 = team['name']
      name_gbk = Iconv.iconv("GBK", "UTF-8", name_utf8)

      if old_team_id != team_id
        current_col = 'J'
        old_team_id = team_id
      else
        current_col.succ!
      end
      row = team_id.to_i + 1
      #puts "#{row}, #{current_col}, #{name_gbk}"
      @excel.set_value(row, current_col, name_gbk)
    end
  end

  def output_team_data
    write_team_column_name
    output_team_infos
    output_team_other_infos
  end

  def close
    @excel.close
    @mysql.close
  end
end
