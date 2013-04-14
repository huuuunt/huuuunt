# encoding: utf-8
# # 球队名称等数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/team_ctrl'

class TeamCmd < CmdParse::Command
  def initialize
    super('team', true)
    self.short_desc = "球队名称等数据处理程序"
    self.description = "球队名称等数据处理程序"
  end
end

class TeamImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "球队名称等数据从Excel中导入到数据库"
    self.description = "球队名称等数据从Excel中导入到数据库"
  end

  def execute(args)
    TeamCtrl.import(args)
  end
end

class TeamExportCmd < CmdParse::Command
  def initialize
    super('export', false)
    self.short_desc = "球队名称等数据从数据库中导出到Excel"
    self.description = "球队名称等数据从数据库中导出到Excel"
  end

  def execute(args)
    TeamCtrl.export(args)
  end
end

class TeamCheckCmd < CmdParse::Command
  def initialize
    super('check', false)
    self.short_desc = "检查球队名称数据库中是否存在重复的数据"
    self.description = "检查球队名称数据库中是否存在重复的数据"
  end

  def execute(args)
    TeamCtrl.check_duplicate_name(args)
  end
end