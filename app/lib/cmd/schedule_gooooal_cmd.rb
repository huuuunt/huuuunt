# 从Gooooal获取的赛程数据处理CMD

require 'rubygems'
require 'cmdparse'

require 'function/schedule_gooooal_ctrl'

class ScheduleGooooalCmd < CmdParse::Command
  def initialize
    super('schedule-gooooal', true)
    self.short_desc = "赛程数据处理程序"
    self.description = "赛程数据处理程序"
  end
end

class ScheduleGooooalPreprocessCmd < CmdParse::Command
    def initialize
    super('preprocess', false)
    self.short_desc = "检查赛程数据是否存在不能识别球队信息"
    self.description = "检查赛程数据是否存在不能识别球队信息"
  end

  def execute(args)
    # args: 2012 1 2
    ScheduleGooooalCtrl.preprocess(args)
  end
end

class ScheduleGooooalImportCmd < CmdParse::Command
  def initialize
    super('import', false)
    self.short_desc = "将预处理好的赛程数据导入数据库"
    self.description = "将预处理好的赛程数据导入数据库"
  end

  def execute(args)
    ScheduleGooooalCtrl.import(args)
  end
end

class ScheduleGooooalUpdatePreprocessCmd < CmdParse::Command
    def initialize
    super('update-preprocess', false)
    self.short_desc = "检查待更新的赛程数据是否存在不能识别球队信息"
    self.description = "检查待更新的赛程数据是否存在不能识别球队信息"
  end

  def execute(args)
    # args: 2012
    ScheduleGooooalCtrl.update_preprocess(args)
  end
end

class ScheduleGooooalUpdateCmd < CmdParse::Command
  def initialize
    super('update', false)
    self.short_desc = "将预处理好的待更新的赛程数据导入数据库"
    self.description = "将预处理好的待更新的赛程数据导入数据库"
  end

  def execute(args)
    # args: 2012
    ScheduleGooooalCtrl.update(args)
  end
end


