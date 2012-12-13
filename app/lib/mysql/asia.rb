
require 'mysql/driver'
require 'util/date_tool'

class Asia

  include Huuuunt::DateTool

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
end

