# encoding: utf-8
# # 球队排名数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/rank_ctrl'

class RankCmd < CmdParse::Command
  def initialize
    super('rank', true)
    self.short_desc = "球队排名数据处理程序"
    self.description = "球队排名数据处理程序"
  end
end

class RankCalcBaseCmd < CmdParse::Command
    def initialize
    super('calc-base', false)
    self.short_desc = "计算球队排名基础数据"
    self.description = "计算球队排名基础数据"
  end

  def execute(args)
    RankCtrl.calc_base(args)
  end
end

class RankCalcHistoryCmd < CmdParse::Command
    def initialize
    super('calc-history', false)
    self.short_desc = "计算球队排名"
    self.description = "计算球队排名"
  end

  def execute(args)
    RankCtrl.calc_history(args)
  end
end


