# encoding: utf-8
# # 联赛积分数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/score_ctrl'

class ScoreCmd < CmdParse::Command
  def initialize
    super('score', true)
    self.short_desc = "联赛积分数据处理程序"
    self.description = "联赛积分数据处理程序"
  end
end

class ScoreCalcCmd < CmdParse::Command
    def initialize
    super('calc', false)
    self.short_desc = "计算联赛积分"
    self.description = "计算联赛积分"
  end

  def execute(args)
    ScoreCtrl.calc(args)
  end
end

class ScoreCheckCmd < CmdParse::Command
  def initialize
    super('check', false)
    self.short_desc = "核对联赛积分是否正确"
    self.description = "核对联赛积分是否正确"
  end

  def execute(args)
    ScoreCtrl.check(args)
  end
end

class SoreAsiaCalcCmd < CmdParse::Command
    def initialize
    super('asia-calc', false)
    self.short_desc = "计算联赛输赢盘排名"
    self.description = "计算联赛输赢盘排名"
  end

  def execute(args)
    ScoreCtrl.asia_calc(args)
  end
end

class ScoreAsiaCheckCmd < CmdParse::Command
  def initialize
    super('asia-check', false)
    self.short_desc = "核对联赛输赢盘统计数据是否正确"
    self.description = "核对联赛输赢盘统计数据是否正确"
  end

  def execute(args)
    ScoreCtrl.asia_check(args)
  end
end

