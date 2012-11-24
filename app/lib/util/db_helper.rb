
module Huuuunt
  module DbHelper
    def self.included(base)
      base.extend Huuuunt::DbHelper
      # 初始化match、team相关数据
      init_match_map
      init_team_map
    end

    @@match_name_map = {}
    @@team_name_map = {}
    @@match_id_map = {}
    @@team_id_map = {}

    def init_match_map
      MatchInfo.all.each do |match|
        @@match_name_map[match.name_cn] = { "id" => match.match_id, "stat" => match.is_stat }
        @@match_id_map[match.match_id] = { "cn" => match.name_cn, "stat" => match.is_stat }
      end
      MatchOtherInfo.all.each do |match|
        stat = @@match_id_map[match.match_id]['stat']
        @@match_name_map[match.name] = { "id" => match.match_id, "stat" => stat }
      end
    end

    def init_team_map
      TeamInfo.all.each do |team|
        @@team_name_map[team.name_cn] = { "id" => team.team_id }
        @@team_id_map[team.team_id] = { "cn" => team.name_cn }
      end
      TeamOtherInfo.all.each do |team|
        @@team_name_map[team.name] = { "id" => team.team_id }
      end
    end

    # 判断赛事名称是否已经在数据库中存在，从@@match_name_map中判断
    def match_name_exist?(name)
      @@match_name_map[name]
    end

    # 判断球队名称是否已经在数据库中存在，从@@team_name_map中判断
    def team_name_exist?(name)
      @@team_name_map[name]
    end

    # 判断该赛事名称是否需要纳入统计，如果stat==0则无需统计
    def match_need_stat?(name)
      @@match_name_map[name]['stat'] > 0
    end

    # 根据赛事名称查询赛事ID
    def get_match_id_by_name(name)
      @@match_name_map[name]['id']
    end

    # 根据球队名称查询球队ID
    def get_team_id_by_name(name)
      @@team_name_map[name]['id']
    end

    def insert_new_match_name(match_name_arr)
      return if match_name_arr.size == 0
      
      # 获取最大的match ID值
      id = MatchInfo.maximum('match_id')
      
      match_infos = []
      match_name_arr.each_with_index do |name, index|
        match_infos << MatchInfo.new(:match_id => id+index,
                               :name_cn => name,
                               :name_tc => '',
                               :name_en => '',
                               :name_jp => '',
                               :match_color => '#000000',
                               :is_stat => 0,
                               :country_id => 0,
                               :bet007_match_id => 0,
                               :phases => 0,
                               :season_type => 0)
      end
      
      MatchInfo.import(match_infos)

      return match_infos.size
    end

    def insert_new_team_name(team_name_arr)
      return if team_name_arr.size == 0

      # 获取最大的match ID值
      id = TeamInfo.maximum('team_id')

      team_infos = []
      team_name_arr.each_with_index do |item, index|
        team_infos << TeamInfo.new(:team_id => id+index,
                                   :name_cn => item['team_name'],
                                   :name_tc => '',
                                   :name_en => '',
                                   :name_jp => '',
                                   :match_id => item['match_id']
                     )
      end

      MatchInfo.import(team_infos)

      return team_infos.size
    end

  end
end

