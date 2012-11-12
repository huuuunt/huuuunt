# 球队名称等数据导入导出处理程序

require 'rubygems'
require 'spreadsheet'

require 'mysql/mysql_driver'
require 'mysql/team_info'
require 'util/excel'

class MatchCtrl

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
    #$logger.debug("MatchInfoFile = #{MatchInfoFile}")
    # 读取excel数据，保存到hash结构中
    book = Spreadsheet.open(TeamInfoFile, 'r')
    match_sheet = book.worksheet("match")
    country_sheet = book.worksheet("country")

    # 写入countries数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table countries")
    country_sheet.each do |row|
      next if row[0] == "CountryId"
      Country.create(:id => row[0],
                     :name_cn => row[1],
                     :name_tw => row[2],
                     :name_en => row[3],
                     :name_jp => row[4],
                     :flag => row[5])
    end

    # 写入match_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table match_infos")
    match_sheet.each do |row|
      next if row[1] == "MatchName"
      country_id = Country.where("name_cn = ?", row[2]).first.id if get_cell_val(row[2])
      TeamInfo.create(:match_id => row[0],
                       :name_cn => row[1],
                       :name_tc => row[4],
                       :name_en => row[5],
                       :name_jp => row[6],
                       :match_color => row[8],
                       :is_stat => row[9],
                       :country_id => country_id,
                       :bet007_match_id => row[10],
                       :phases => row[11],
                       :season_type => row[12])
    end

    # 写入match_other_infos数据库表
    ActiveRecord::Base.connection.execute("TRUNCATE table match_other_infos")
    match_sheet.each do |row|
      next if row[1] == "MatchName"
      start = 14
      while get_cell_val(row[start])
        TeamOtherInfo.create(:match_id => row[0], :name => row[start])
        start += 1
      end
    end
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

    # 读取数据库表team_infos，并按字段名称写入team中
    TeamInfo.all.each do |t|
      index = t.team_id
      team_sheet[index, 0] = t.team_id
      team_sheet[index, 1] = t.name_cn
      
      team_sheet[index, 3] = t.match_id
      team_sheet[index, 4] = t.name_tc
      team_sheet[index, 5] = t.name_en
      team_sheet[index, 6] = t.name_jp
    end

    # 读取球队对应的赛事名称，写入team中
    TeamInfo.getAllMatchName

    # 读取team_other_infos数据库表，按字段名称写入team中
    c = Hash.new(9)
    TeamOtherInfo.order("team_id").each do |mo|
      index = mo.team_id
      team_sheet[index, c[index]] = mo.name
      c[index] += 1
    end

    # 写入match.xls文件
    book.write(TeamInfoFile)
  end
end