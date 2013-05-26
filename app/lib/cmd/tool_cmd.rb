# 工具类CMD

require 'rubygems'
require 'cmdparse'

require 'function/tool_ctrl'

class ToolCmd < CmdParse::Command
  def initialize
    super('tool', true)
    self.short_desc = "球队排名数据处理程序"
    self.description = "球队排名数据处理程序"
  end
end

class ToolChangeTeamNoCmd < CmdParse::Command
    def initialize
    super('changeteamno', false)
    self.short_desc = "计算球队排名基础数据"
    self.description = "计算球队排名基础数据"
  end

  def execute(args)
    ToolCtrl.changeTeamNo
  end
end


