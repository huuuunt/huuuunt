# 赛事名称等数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/match_ctrl'

class MatchCmd < CmdParse::Command
  def initialize
    super('match', true)
    self.short_desc = "赛事名称等数据处理程序"
    self.description = "赛事名称等数据处理程序"
  end
end

class MatchImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "赛事名称等数据从Excel中导入到数据库"
    self.description = "赛事名称等数据从Excel中导入到数据库"
  end

  def execute(args)
    MatchCtrl.import(args)
  end
end

class MatchExportCmd < CmdParse::Command
  def initialize
    super('export', false)
    self.short_desc = "赛事名称等数据从数据库中导出到Excel"
    self.description = "赛事名称等数据从数据库中导出到Excel"
  end

  def execute(args)
    MatchCtrl.export(args)
  end
end

class MatchCheckCmd < CmdParse::Command
  def initialize
    super('check', false)
    self.short_desc = "检查赛事名称数据库中是否存在重复的数据"
    self.description = "检查赛事名称数据库中是否存在重复的数据"
  end

  def execute(args)
    MatchCtrl.check_duplicate_name(args)
  end
end
