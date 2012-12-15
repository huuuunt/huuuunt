
require 'mysql/driver'

class Match < ActiveRecord::Base

  cattr_accessor :match_name_map
  cattr_accessor :match_id_map

  cattr_accessor :match_need_stat

  @@match_name_map = {}
  @@match_id_map = {}

  Match.all.each do |match|
    @@match_name_map[match.name_cn] = { "id" => match.match_id, "import" => match.need_import }
    1.upto(10) do |x|
      src = <<-END_SRC
        @@match_name_map[match.name#{x}] = { "id" => match.match_id, "import" => match.need_import } if match.name#{x}
      END_SRC
      eval src
    end
    @@match_id_map[match.match_id] = { "name" => match.name_cn, "import" => match.need_import }
  end
#  MatchOther.all.each do |match|
#    import = @@match_id_map[match.match_id]['import']
#    @@match_name_map[match.name] = { "id" => match.match_id, "import" => import }
#  end

  @@match_need_stat = {}

  Match.where("season_type!=0").each do |match|
    @@match_need_stat[match.match_id] = {
                                          "bet007" => match.bet007_match_id,
                                          "phases" => match.phases ,
                                          "type"   => match.season_type
                                        }
  end

  # 验证数据初始化成功代码,其中存在可能重复的数据，因此总数略少
#  @@match_name_map.each do |key, value|
#    puts "#{key}, #{value['id']}, #{value['import']}"
#  end

#  @@match_id_map.each do |key, value|
#    puts "#{key}, #{value['name']}, #{value['import']}"
#  end

#  @@match_need_stat.each do |key, value|
#    puts "#{key}, #{value['bet007']}, #{value['phases']}, #{value['type']}"
#  end

  class << self
    def get_country_name
      find_by_sql("SELECT m.id, m.match_id, m.name_cn match_name, m.country_id, c.name_cn country_name
                             FROM #{$tab['match']} m
                             inner join #{$tab['country']} c
                             where m.country_id = c.id")
    end

    def get_all_matchname
      find_by_sql("select match_id, name_cn from #{$tab['match']}")
    end

    # 判断赛事名称是否已经在数据库中存在，从@@match_name_map中判断
    def match_name_exist?(name)
      @@match_name_map[name]
    end

    # 判断该赛事名称相关的数据是否需要导入，如果stat==0则无需导入
    def match_need_import?(name)
      return FALSE unless @@match_name_map[name]
      @@match_name_map[name]['import']
    end

    # 判断该赛事是否要纳入统计
    def match_need_stat?(match_id)
      return @@match_need_stat.has_key?(match_id.to_i)
    end

    def get_bet007_match_id(match_id)
      @@match_need_stat[match_id.to_i]['bet007']
    end

    def get_phases(match_id)
      @@match_need_stat[match_id.to_i]['phases']
    end

    # 赛事是否跨年
    def match_schedule_two_year?(match_id)
      @@match_need_stat[match_id.to_i]['type']==1
    end

    # 根据赛事名称查询赛事ID
    def get_match_id_by_name(name)
      @@match_name_map[name]['id']
    end

    # 批量插入赛事信息
    def insert_new_match_name(match_name_arr)
      return 0 if match_name_arr.size == 0

      # 获取最大的match ID值
      id = Match.maximum('match_id')

      match_infos = []
      # 由于无法确定activerecord的import代码是否支持unique方式，因此在外部实现
      match_unique = []
      match_name_arr.each_with_index do |name, index|
        next if match_unique.include?(name)
        match_unique << name
        $logger.warn("insert new match name : #{name}")

        match_infos << Match.new(:match_id => id+index,
                               :name_cn => name,
                               :name_tc => '',
                               :name_en => '',
                               :name_jp => '',
                               :match_color => '#000000',
                               :need_import => 0,
                               :country_id => 0,
                               :bet007_match_id => 0,
                               :phases => 0,
                               :season_type => 0)
      end

      Match.import(match_infos)

      return match_infos.size
    end

    # 选择性插入赛事名称数据
    # 1、如果简体名称和繁体名称在数据库中都不存在，则需要展示出来
    # 2、如果简体名称和繁体名称在数据库中都存在，则无需处理
    # 3、如果简体名称和繁体名称只有一个在数据库中存在，则将另一个插入到match_other_infos数据库表中
    def select_insert_match_name(match_name_arr)
      match_others = []
      match_name_arr.each do |item|
        name_cn = item[:name_cn]
        name_tw = item[:name_tw]

        # 如果都存在，则无需处理
        if match_name_exist?(name_cn) &&
            match_name_exist?(name_tw)
          next
        end

        # 程序自动处理（name_cn和name_tw必然有一个已经在数据库中存在，需要将另外一个加入数据库）
        if match_name_exist?(name_cn)
          match_id = get_match_id_by_name(name_cn)
          # 将name_tw写入matches数据库表中
          match = where("match_id = #{match_id}").first
          1.upto(10) do |x|
            src = <<-END_SRC
              unless match.name#{x}
                match.name#{x} = name_tw
                match.save
                break
              end
            END_SRC
            eval src
          end
          #match_others << MatchOther.new(:match_id => match_id, :name => name_tw)
        end

        if match_name_exist?(name_tw)
          match_id = get_match_id_by_name(name_tw)
          # 将name_cn写入matches数据库表中
          match = where("match_id = #{match_id}").first
          1.upto(10) do |x|
            src = <<-END_SRC
              unless match.name#{x}
                match.name#{x} = name_cn
                match.save
                break
              end
            END_SRC
            eval src
          end
          #match_others << MatchOther.new(:match_id => match_id, :name => name_cn)
        end
      end

      #MatchOther.import(match_others)
    end
  end
end

