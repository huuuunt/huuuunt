
require 'mysql/driver'
require 'util/date_tool'
require 'util/common'

class Asia

  include Huuuunt::DateTool
  include Huuuunt::Common

  cattr_accessor :companies
  # 亚洲赔率公司
  @@companies = [
      "sb_asias",       # 3     SB
      "jbb_asias",      # 23    金宝博
      "bet12_asias",    # 24    12bet
      "lj_asias",       # 31    利记
      "ylg_asias",      # 33    永利高
      "macro_asias",    # 1     澳门
      "bet365_asias",   # 8     BET365
      "libo_asias",     # 4     立博
      "weide_asias",    # 14    韦德
      "ysb_asias",      # 12    易胜博
      "bet10_asias",    # 22    10Bet
      "ms_asias",       # 17    明陞
      "yh_asias"        # 35    盈禾
  ]

  def self.latest_date(format)
    latest_datetime = YsbAsia.maximum('matchdt').strftime('%Y-%m-%d %H:%M:%S')

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

