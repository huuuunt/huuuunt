
require 'mysql/driver'

class TeamHelper
  cattr_accessor :team_name_map
  cattr_accessor :team_id_map
  @@team_name_map = {}
  @@team_id_map = {}

  Team.all.each do |team|
    @@team_name_map[team.name_cn] = { "id" => team.team_id }
    @@team_id_map[team.team_id] = { "cn" => team.name_cn }
  end
  TeamOther.all.each do |team|
    @@team_name_map[team.name] = { "id" => team.team_id }
  end

  class << self
    # 判断球队名称是否已经在数据库中存在，从@@team_name_map中判断
    def team_name_exist?(name)
      @@team_name_map[name]
    end

    # 根据球队名称查询球队ID
    def get_team_id_by_name(name)
      @@team_name_map[name]['id']
    end

    def insert_new_team_name(team_name_arr)
      return 0 if team_name_arr.size == 0

      # 获取最大的match ID值
      id = Team.maximum('team_id')

      team_infos = []
      team_name_arr.each_with_index do |item, index|
        team_infos << Team.new(:team_id => id+index,
                                   :name_cn => item['team_name'],
                                   :name_tc => '',
                                   :name_en => '',
                                   :name_jp => '',
                                   :match_id => item['match_id']
                     )
      end

      Team.import(team_infos)

      return team_infos.size
    end

    # 选择性插入球队名称数据
    # 1、如果简体名称和繁体名称在数据库中都不存在，则需要展示出来
    # 2、如果简体名称和繁体名称在数据库中都存在，则无需处理
    # 3、如果简体名称和繁体名称只有一个在数据库中存在，则将另一个插入到team_other_infos数据库表中
    def select_insert_team_name(team_name_arr)
      team_others = []
      team_name_arr.each do |item|
        name_cn = item[:name_cn]
        name_tw = item[:name_tw]

        # 如果都存在，则无需处理
        if team_name_exist?(name_cn) &&
            team_name_exist?(name_tw)
          next
        end

        # 程序自动处理（name_cn和name_tw必然有一个已经在数据库中存在，需要将另外一个加入数据库）
        if team_name_exist?(name_cn)
          team_id = get_team_id_by_name(name_cn)
          # 将name_tw写入team_other_infos数据库表中
          team_others << TeamOther.new(:team_id => team_id, :name => name_tw)
        end

        if team_name_exist?(name_tw)
          team_id = get_team_id_by_name(name_tw)
          # 将name_cn写入team_other_infos数据库表中
          team_others << TeamOther.new(:team_id => team_id, :name => name_cn)
        end
      end

      TeamOther.import(team_others)
    end
  end
end

