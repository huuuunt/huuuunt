# 球队名称等数据导入导出处理程序

require 'rubygems'
require 'spreadsheet'

require 'mysql/team_info'
require 'util/excel'

class TeamCtrl

  include Huuuunt::Excel

  TeamInfoFile = File.expand_path("../../data/base/team.xls", File.dirname(__FILE__))
  # team excel 字段名称
  TEAM_COLS_NAME = [
    "TeamNo", "TeamName", "MatchName", "MatchNo",
    "TeamNameTn", "TeamNameEn", "TeamNameJp", "", "",
    "TeamName1", "TeamName2", "TeamName3", "TeamName4", "TeamName5",
    "TeamName6", "TeamName7", "TeamName8", "TeamName9", "TeamName10"
  ]

  # 将球队名称等相关数据导入数据库
  def self.import(args)
    # 读取excel数据，保存到hash结构中
    book = Spreadsheet.open(TeamInfoFile, 'r')
    team_sheet = book.worksheet("team")

    # 写入team_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table team_infos")
    teams = []
    team_sheet.each do |row|
      next if row[1] == "TeamName"
      teams << TeamInfo.new( :team_id => row[0],
                             :name_cn => row[1],
                             :name_tc => row[4],
                             :name_en => row[5],
                             :name_jp => row[6],
                             :match_id => row[3]
                     )
    end
    TeamInfo.import(teams)

    # 写入team_other_infos数据库表
    team_others = []
    ActiveRecord::Base.connection.execute("TRUNCATE table team_other_infos")
    team_sheet.each do |row|
      next if row[1] == "TeamName"
      start = 9
      while get_cell_val(row[start])
        team_others << TeamOtherInfo.new(:team_id => row[0], :name => row[start])
        start += 1
      end
    end
    TeamOtherInfo.import(team_others)
  end

  # 将球队名称等相关数据导出到Excel中
  def self.export(args)
    # 转存原有team.xls文件，文件名加上时间戳
    FileUtils.mv(TeamInfoFile, TeamInfoFile+".#{Time.now.to_i}") if File.exist?(TeamInfoFile)

    # 创建新team.xls文件，并写入每列字段名称
    book = Spreadsheet::Workbook.new
    team_sheet = book.create_worksheet(:name => "team")

    TEAM_COLS_NAME.each_with_index do |col_name, index|
      team_sheet[0, index] = col_name
    end

    # 读取球队对应的赛事名称，保存成hash
    match = {}
    MatchInfo.get_all_matchname.each do |m|
      match[m.match_id] = m.name_cn
    end
    
    # 读取数据库表team_infos，并按字段名称写入team中
    TeamInfo.all.each do |t|
      index = t.team_id
      team_sheet[index, 0] = t.team_id
      team_sheet[index, 1] = t.name_cn
      team_sheet[index, 2] = match[t.match_id]
      team_sheet[index, 3] = t.match_id
      team_sheet[index, 4] = t.name_tc
      team_sheet[index, 5] = t.name_en
      team_sheet[index, 6] = t.name_jp
    end    

    # 读取team_other_infos数据库表，按字段名称写入team中
    c = Hash.new(9)
    TeamOtherInfo.order("team_id").each do |to|
      index = to.team_id
      team_sheet[index, c[index]] = to.name
      c[index] += 1
    end

    # 写入match.xls文件
    book.write(TeamInfoFile)
  end
end