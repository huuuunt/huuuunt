
require 'mysql/driver'
require 'mysql/match'

class Team < ActiveRecord::Base

  cattr_accessor :team_name_map
  cattr_accessor :team_id_map
  @@team_name_map = {}
  @@team_id_map = {}

  Team.all.each do |team|
    @@team_name_map[team.name_cn] = { "id" => team.team_id }
    1.upto(10) do |x|
      src = <<-END_SRC
        @@team_name_map[team.name#{x}] = { "id" => team.team_id } if team.name#{x}
      END_SRC
      eval src
    end
    @@team_id_map[team.team_id] = { "cn" => team.name_cn }
  end
#  TeamOther.all.each do |team|
#    @@team_name_map[team.name] = { "id" => team.team_id }
#  end

  # 验证数据初始化成功代码
#  @@team_name_map.each do |key, value|
#    puts "#{key}, #{value['id']}, #{value['import']}"
#  end

#  @@team_id_map.each do |key, value|
#    puts "#{key}, #{value['name']}, #{value['import']}"
#  end

  class << self

    def update_team_name_map(team_name, team_id)
      @@team_name_map[team_name] = { "id" => team_id }
    end
    
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
      # 由于无法确定activerecord的import代码是否支持unique方式，因此在外部实现
      team_unique = []
      team_name_arr.each_with_index do |item, index|
        next if team_unique.include?(item['team_name'])
        team_unique << item['team_name']
        $logger.warn("insert new team name : #{item['team_name']}, #{Match.match_id_map[item['match_id'].to_i]['name']}")
        
        team_infos << Team.new(:team_id => id+index,
                                   :name_cn => item['team_name'],
                                   :name_tw => '',
                                   :name_en => '',
                                   :name_jp => '',
                                   :match_id => item['match_id']
                     )
        update_team_name_map(item['team_name'], id+index)
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
        name_cn = item["name_cn"]
        name_tw = item["name_tw"]

        # 如果都存在，则无需处理
        if team_name_exist?(name_cn) &&
            team_name_exist?(name_tw)
          next
        end
        
        # 程序自动处理（name_cn和name_tw必然有一个已经在数据库中存在，需要将另外一个加入数据库）
        if team_name_exist?(name_cn)          
          team_id = get_team_id_by_name(name_cn)
          # 将name_tw写入teams数据库表中
          team = where("team_id = #{team_id}").first
          1.upto(10) do |x|
            src = <<-END_SRC
              unless team.name#{x}
                team.name#{x} = name_tw
                team.save
                break
              end
            END_SRC
            eval src
          end
          update_team_name_map(name_tw, team_id)
        end

        if team_name_exist?(name_tw)
          team_id = get_team_id_by_name(name_tw)
          # 将name_cn写入teams数据库表中
          team = where("team_id = #{team_id}").first
          1.upto(10) do |x|
            src = <<-END_SRC
              unless team.name#{x}
                team.name#{x} = name_cn
                team.save
                break
              end
            END_SRC
            eval src
          end
          update_team_name_map(name_cn, team_id)
        end
      end
    end
  end
end

