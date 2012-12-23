
require 'mysql/driver'
require 'mysql/match'
require 'mysql/result'
require 'mysql/europe'
require 'mysql/asia'

class Team < ActiveRecord::Base

  cattr_accessor :team_name_map
  cattr_accessor :team_id_map
  @@team_name_map = {}
  @@team_id_map = {}

  # 生成缓存数据，同时验证是否存在重复的球队名称
  Team.all.each do |team|
    if @@team_name_map.include?(team.name_cn)
      puts "(1) #{team.name_cn},#{team.team_id} has exist!"
    end
    @@team_name_map[team.name_cn] = { "id" => team.team_id }
    1.upto(10) do |x|
      src = <<-END_SRC
        team_name = team.name#{x}
        if team_name && team_name.size>0
          if @@team_name_map.include?(team_name)
            puts "(2) " + team_name + "(" + team.team_id.to_s + ") has exist!"
          end
          @@team_name_map[team.name#{x}] = { "id" => team.team_id }
        end
      END_SRC
      eval src
    end
    @@team_id_map[team.team_id] = { "cn" => team.name_cn }
  end
#  TeamOther.all.each do |team|
#    @@team_name_map[team.name] = { "id" => team.team_id }
#  end

#  # 验证数据初始化成功代码
#  puts @@team_name_map.size
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

    def update_team_id_map(team_name, team_id)
      @@team_id_map[team_id] = { "cn" => team_name }
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
      # 因为要去除重复的名称，就不能使用Array自带的each_with_index，需要外部定义一个index
      index = 0
      team_name_arr.each do |item|
        next if team_unique.include?(item['team_name'])
        team_unique << item['team_name']
        $logger.warn("insert new team name : #{item['team_name']}, #{Match.match_id_map[item['match_id'].to_i]['name']}")

        team_infos << Team.new(:team_id => id+index+1,
                                   :name_cn => item['team_name'],
                                   :name_tw => nil,
                                   :name_en => nil,
                                   :name_jp => nil,
                                   :match_id => item['match_id']
                     )
        update_team_name_map(item['team_name'], id+index+1)
        update_team_id_map(item['team_name'], id+index+1)
        index += 1
      end

      Team.import(team_infos)

      return team_infos.size
    end

    # 选择性插入球队名称数据
    # 1、如果简体名称和繁体名称在数据库中都不存在，则需要展示出来
    # 2、如果简体名称和繁体名称在数据库中都存在，则无需处理
    # 3、如果简体名称和繁体名称只有一个在数据库中存在，则将另一个插入到teams数据库表中
    def select_insert_team_name(team_name_arr)
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
              if team.name#{x} && team.name#{x}.size>0
              else
                team.name#{x} = name_tw
                team.save
                break
              end
            END_SRC
            eval src
          end
          update_team_name_map(name_tw, team_id)
          # 注意这里就可以next了，否则下面这个team_name_exist?(name_tw)会受影响，造成数据错误
          next
        end

        if team_name_exist?(name_tw)
          team_id = get_team_id_by_name(name_tw)
          # 将name_cn写入teams数据库表中
          team = where("team_id = #{team_id}").first
          1.upto(10) do |x|
            src = <<-END_SRC
              if team.name#{x} && team.name#{x}.size>0
              else
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

    # 检查是否存在重复的球队名称
    # 如果存在重复的球队名称，则修复，修复存在两种情况。
    # 情况一：name_cn数据重复
    # 情况二：name1～10数据重复
    def check_duplicate_name
      team_name_check = {}
      Team.all.each do |team_obj|
        if team_name_check.include?(team_obj.name_cn)
          puts "(1) #{team_obj.name_cn},#{team_obj.team_id} has exist!"

          # 此时已确定team.name_cn已经存在，则可以直接获取已存在的球队的ID数据
          dest_team_id = team_name_check[team_obj.name_cn]['id'].to_i
          dest_team_obj = Team.where("team_id=#{dest_team_id}").first

          # 将待删除球队记录的繁体名称和英文名称，复制到已有球队记录中
          dest_team_obj.name_tw = team_obj.name_tw unless dest_team_obj.name_tw
          dest_team_obj.name_en = team_obj.name_en unless dest_team_obj.name_en
          dest_team_obj.save

          # 将重复的数据修改成TEMP%d格式
          team_obj.name_cn = "TEMP#{team_obj.team_id}"
          team_obj.name_tw = nil
          team_obj.name_en = nil
          team_obj.save

          # 1.处理name1～10的数据，迁移到正确的数据记录中去
          tmp_teams = []
          1.upto(10) do |x|
            src = <<-END_SRC
              team_name = team_obj.name#{x}
              if team_name && team_name.size>0
                tmp_teams << team_name
                team_obj.name#{x} = nil
                team_obj.save
              end
            END_SRC
            eval src
          end
          tmp_teams.each do |t_name|
            1.upto(10) do |x|
              src = <<-END_SRC
                if dest_team_obj.name#{x} && dest_team_obj.name#{x}.size>0
                else
                  dest_team_obj.name#{x} = t_name
                  dest_team_obj.save
                  break
                end
              END_SRC
              eval src
            end
          end

          # 2.处理赛果数据
          Result.update_team_id(team_obj.team_id.to_i, dest_team_obj.team_id.to_i)

          # 3.处理赔率数据
          Europe.update_team_id(team_obj.team_id.to_i, dest_team_obj.team_id.to_i)
          Asia.update_team_id(team_obj.team_id.to_i, dest_team_obj.team_id.to_i)
        end

        team_name_check[team_obj.name_cn] = { "id" => team_obj.team_id }
        1.upto(10) do |x|
          src = <<-END_SRC
            team_name = team_obj.name#{x}
            if team_name && team_name.size>0
              if team_name_check.include?(team_name)
                puts "(2) " + team_name + "(" + team_obj.team_id.to_s + ") has exist!"
                team_obj.name#{x} = nil
                team_obj.save
              else
                team_name_check[team_obj.name#{x}] = { "id" => team_obj.team_id }
              end
            end
          END_SRC
          eval src
        end
      end
    end
    
  end # class << self
end

