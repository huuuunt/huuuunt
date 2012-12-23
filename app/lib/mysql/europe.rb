
require 'mysql/driver'
require 'util/date_tool'
require 'util/common'

class Europe
  
  include Huuuunt::DateTool
  include Huuuunt::Common

  cattr_accessor :companies
  # 欧洲赔率公司
  @@companies = [
    "will_europes",         # 9     威廉希尔
    "weide_europes",        # 14    韦德
    "libo_europes",         # 4     立博
    "macro_europes",        # 1     澳门
    "bet365_europes",       # 8     BET365
    "eurobet_europes",      # 18    Eurobet
    "ysb_europes",          # 12    易胜博
    "interwetten_europes",  # 19    Interwetten
    "snai_europes",         # 7     SNAI
    "sb_europes",           # 3     SB
    "jbb_europes",          # 23    金宝博
    "bet12_europes",        # 24    12bet
    "lj_europes",           # 31    利记
    "bet10_europes",        # 22    10Bet
    "ylg_europes",          # 33    永利高
    "ms_europes",           # 17    明陞
    "yh_europes"            # 35    盈禾
  ]

  def self.latest_date(format)
    latest_datetime = YsbEurope.maximum('matchdt').strftime('%Y-%m-%d %H:%M:%S')

    return latest_date_format(latest_datetime, format)
  end

  # 替换team_id
  def self.update_team_id(s_id, d_id)
    update_home_team_id(s_id, d_id)
    update_away_team_id(s_id, d_id)
  end

  def self.update_home_team_id(s_id, d_id)
    @@companies.each do |company|
      company_class_name = company.singularize.titleize.split.join
      company_obj = []
      src = <<-END_SRC
        company_obj = #{company_class_name}.where("team1no = #{s_id}")
      END_SRC
      eval src
      
      company_obj.each do |r|
        datetime = r.matchdt.strftime('%Y-%m-%d %H:%M:%S')
        new_matchinfono = create_matchinfono2(datetime, r.matchno, d_id, r.team2no)
        r.matchinfono = new_matchinfono
        r.team1no = d_id
        r.save
      end
    end
  end

  def self.update_away_team_id(s_id, d_id)
    @@companies.each do |company|
      company_class_name = company.singularize.titleize.split.join
      company_obj = []
      src = <<-END_SRC
        company_obj = #{company_class_name}.where("team2no = #{s_id}")
      END_SRC
      eval src

      company_obj.each do |r|
        datetime = r.matchdt.strftime('%Y-%m-%d %H:%M:%S')
        new_matchinfono = create_matchinfono2(datetime, r.matchno, r.team1no, d_id)
        r.matchinfono = new_matchinfono
        r.team2no = d_id
        r.save
      end
    end    
  end

end

