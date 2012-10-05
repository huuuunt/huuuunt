require 'rubygems'
require 'mysql'
require 'date'


class MysqlAccess
  #MYSQL_IP = "192.168.21.165"
  MYSQL_IP = "localhost"
  MYSQL_USER = "root"
  MYSQL_PASSWORD = "mysql"
  MYSQL_SCHEMA = "huuuunt_development"
  @@orginal_match_map  = {};
  @@orginal_team_map  = {};
  @@stat_teams = {};
  @@multi_match_map = {};
  @@multi_team_map = {};
  @@new_match_map  = {};
  @@new_team_map  = {};
  @@new_matchs = [];
  @@new_teams = [];

  def initialize
    @conn = Mysql.new(MYSQL_IP, MYSQL_USER, MYSQL_PASSWORD, MYSQL_SCHEMA)
    #conn.query("set names 'utf8'")
    @conn.query("set character_set_connection='utf8'")
    @conn.query("set character_set_results='utf8'")
    @conn.query("set character_set_client=binary")
    init_match_map()
    init_team_map()
  end

  def init_stat_teams
    team_arr = @conn.query("SELECT distinct team1no, matchno FROM matches m where matchno
                            in (1,2,9,10,18,19,24,25,28,29,32,34,38,40,42,54,56,62,69,76,111,127)
                            order by matchno, team1no")
    team_arr.each do |data|
      @@stat_teams[data[0].to_i] = data[1]
    end
  end

  def create_europe_bet_table_if_not_exist(table_name)

    table_schema =  "CREATE TABLE IF NOT EXISTS `#{table_name}` (
    `id` int(11) NOT NULL auto_increment,
    `matchinfono` varchar(255) collate utf8_unicode_ci default NULL,
    `matchdt` datetime default NULL,
    `matchno` int(11) default NULL,
    `team1no` int(11) default NULL,
    `team2no` int(11) default NULL,
    `initwin` int(11) default NULL,
    `initdeuce` int(11) default NULL,
    `initloss` int(11) default NULL,
    `finwin` int(11) default NULL,
    `findeuce` int(11) default NULL,
    `finloss` int(11) default NULL,
    `result` int(11) default NULL,
    `goal1` int(11) default NULL,
    `goal2` int(11) default NULL,
    `created_at` datetime default NULL,
    `updated_at` datetime default NULL,
      PRIMARY KEY  (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
    @conn.query(table_schema)
    @conn.query("commit")
  end

  def create_bet_table_if_not_exist(table_name)

    table_schema =  "CREATE TABLE IF NOT EXISTS `#{table_name}` (
    `id` int(11) NOT NULL auto_increment,
    `matchinfono` varchar(255) collate utf8_unicode_ci default NULL,
    `matchdt` datetime default NULL,
    `matchno` int(11) default NULL,
    `team1no` int(11) default NULL,
    `team2no` int(11) default NULL,
    `initrate` int(11) default NULL,
    `finrate` int(11) default NULL,
    `uplevel` int(11) default NULL,
    `downlevel` int(11) default NULL,
    `result` int(11) default NULL,
    `halfgoal1` int(11) default NULL,
    `halfgoal2` int(11) default NULL,
    `goal1` int(11) default NULL,
    `goal2` int(11) default NULL,
    `direction` int(11) default NULL,
    `created_at` datetime default NULL,
    `updated_at` datetime default NULL,
    PRIMARY KEY  (`id`)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
    @conn.query(table_schema)
    @conn.query("commit")
  end

  def create_full_matchno(matchno)
    full_matchno = ""
    case matchno.to_s.length
      when 1
        return full_matchno = "000#{matchno}"
      when 2
        return full_matchno = "00#{matchno}"
      when 3
        return full_matchno = "0#{matchno}"
      when 4
        return full_matchno.to_s
      else
        puts "matchno(#{matchno}) length(#{matchno.to_s.length}) error!"
    end
  end

  def create_full_teamno(teamno)
    full_teamno = ""
    case teamno.to_s.length
      when 1
        return full_teamno = "0000#{teamno}"
      when 2
        return full_teamno = "000#{teamno}"
      when 3
        return full_teamno = "00#{teamno}"
      when 4
        return full_teamno = "0#{teamno}"
      when 5
        return full_teamno
      else
        puts "teamno(#{teamno}) length(#{teamno.to_s.length}) error!"
    end
  end

  def create_matchinfono(date, matchno, team1no, team2no)
    "#{date.split('-').join}#{create_full_matchno(matchno)}" +
            "#{create_full_teamno(team1no)}#{create_full_teamno(team2no)}"
  end

  def check_europe_data_exist_in_results(bet_data, match_set)
    all_exist = true

    bet_data.each do |bet|
      match_name = bet[:name]
      match_no =  @@orginal_match_map[match_name][0].to_i
      if !match_set.include?(match_no)
        #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)} need not to statistic"
        next
      end
      #if is_match_stat(match_name) != 1
      #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)} need not to statistic"
      #  next
      #end
      home = bet[:home]
      away = bet[:away]
      team1no =  @@orginal_team_map[home]
      team2no =  @@orginal_team_map[away]
      #if is_team_stat(team1no) != 1 && is_team_stat(team2no) != 1
      #puts "Team:#{Iconv.iconv("GBK", "UTF-8", match_name)},#{Iconv.iconv("GBK", "UTF-8", home)}:#{Iconv.iconv("GBK", "UTF-8", away)} need not to statistic"
      #    next
      #end
      peilv = bet[:peilv]
      peilv_arr = peilv.split(";")
      match_date = bet[:match_date]
      goal1 = bet[:goal1]
      goal2 = bet[:goal2]
      result = bet[:result]

      match_date = bet[:match_date]
      matchinfono = create_matchinfono(match_date[0, match_date.index(" ")], match_no, team1no, team2no)

      status = bet[:status]
      if status==-12 || status==-14
        puts "NOT END: date[#{match_date}] of matchinfono:#{matchinfono}, #{match_name},#{home}:#{away}!"
        next
      end

      result_arr = @conn.query("select matchinfono from results where matchinfono='#{matchinfono}'")

      if  result_arr.num_rows == 0
        all_exist = false
        puts "Result date[#{match_date}] of matchinfono:#{matchinfono}, #{match_name},#{home}:#{away} not exist!"
      end
    end

    return all_exist
  end

  def insert_europe_bet_data(bet_data, company_tables, match_set)
    bet_data.each do |bet|
      match_name = bet[:name]
      match_no =  @@orginal_match_map[match_name][0].to_i
      if !match_set.include?(match_no)
        #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)} need not to statistic"
        next
      end
      #if is_match_stat(match_name) != 1
      #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)} need not to statistic"
      #  next
      #end
      home_tn = bet[:home_tn]
      away_tn = bet[:away_tn]
      home = bet[:home]
      away = bet[:away]
      team1no =  @@orginal_team_map[home]
      team2no =  @@orginal_team_map[away]
      #if is_team_stat(team1no) != 1 && is_team_stat(team2no) != 1
      #    puts "Team:#{Iconv.iconv("GBK", "UTF-8", match_name)},#{Iconv.iconv("GBK", "UTF-8", home)}:#{Iconv.iconv("GBK", "UTF-8", away)} need not to statistic"
      #    next
      #end
      peilv = bet[:peilv]
      peilv_arr = peilv.split(";")
      match_date = bet[:match_date]
      goal1 = bet[:goal1]
      goal2 = bet[:goal2]
      result = bet[:result]

      match_date = bet[:match_date]
      matchinfono = create_matchinfono(match_date[0, match_date.index(" ")], match_no, team1no, team2no)

      status = bet[:status]
      if status==-12 || status==-14
        puts "NOT END: date[#{match_date}] of matchinfono:#{matchinfono}, #{match_name},#{home}:#{away}!"
        next
      end

      company_tables.each_with_index do |company, index|
        unless peilv_arr[index].nil?
          if /[\d]/.match(peilv_arr[index])
            pellv_company =  peilv_arr[index].split(",")

            pellv_company.each_with_index do |peilv, index|
              next if index==0 # 第一个是用于查找赔率变化数据的ID
              #puts "#{peilv}, #{peilv.class}"
              pellv_company[index] = (pellv_company[index].to_f*1000).to_i
              #puts "#{peilv}, #{peilv.class}"
            end

            sql = "insert into #{company} (matchinfono, matchdt, matchno, team1no, team2no, initwin, initdeuce,
                                                  initloss, finwin, findeuce, finloss, result, goal1, goal2, changeid, home, away)
                 values ('#{matchinfono}','#{match_date}', #{match_no}, #{team1no}, #{team2no}, #{pellv_company[1]}, #{pellv_company[2]},
                          #{pellv_company[3]}, #{pellv_company[4]}, #{pellv_company[5]}, #{pellv_company[6]},
                          #{result}, #{goal1}, #{goal2}, #{pellv_company[0]}, '#{home_tn}', '#{away_tn}')"
            odd_arr = @conn.query("select matchinfono from #{company} where matchinfono='#{matchinfono}'")
            if odd_arr.num_rows == 0
              #puts sql
              @conn.query(sql)
            else
              sql = "update #{company} set matchdt='#{match_date}', matchno=#{match_no},
                    team1no=#{team1no}, team2no=#{team2no}, initwin=#{pellv_company[1]}, initdeuce=#{pellv_company[2]},
                    initloss=#{pellv_company[3]}, finwin=#{pellv_company[4]}, findeuce=#{pellv_company[5]},
                    finloss=#{pellv_company[6]}, result=#{result}, goal1=#{goal1}, goal2=#{goal2},
                    changeid=#{pellv_company[0]}, home='#{home_tn}', away='#{away_tn}'
                    where matchinfono='#{matchinfono}'"
              #puts sql
              @conn.query(sql)
            end

          end
        end
      end
    end
    commit()
  end


  def insert_asia_bet_data(bet_data, company_tables, match_set)
    bet_data.each do |bet|
      match_name = bet[:name]
      match_no =  @@orginal_match_map[match_name][0].to_i
      if !match_set.include?(match_no)
        #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)}, #{match_no}, #{match_no.class} need not to statistic"
        next
      end
      #if is_match_stat(match_name) != 1
      #  #puts "Match:#{Iconv.iconv("GBK", "UTF-8", match_name)} need not to statistic"
      #  next
      #end
      home = bet[:home]
      away = bet[:away]
      team1no =  @@orginal_team_map[home]
      team2no =  @@orginal_team_map[away]
      #if is_team_stat(team1no) != 1 && is_team_stat(team2no) != 1
      #    puts "Team:#{Iconv.iconv("GBK", "UTF-8", match_name)},#{Iconv.iconv("GBK", "UTF-8", home)}:#{Iconv.iconv("GBK", "UTF-8", away)} need not to statistic"
      #    next
      #end

      peilv = bet[:peilv]
      peilv_arr = peilv.split(";")
      match_date = bet[:match_date] 
      halfgoal1 = bet[:halfgoal1]
      halfgoal2 = bet[:halfgoal2]
      goal1 = bet[:goal1]
      goal2 = bet[:goal2]
      #result = bet[:result]
      direction = bet[:direction]

      matchinfono = create_matchinfono(match_date[0, match_date.index(" ")], match_no, team1no, team2no)

      status = bet[:status]
      if status==-12 || status==-14
        puts "NOT END: date[#{match_date}] of matchinfono:#{matchinfono}, #{match_name},#{home}:#{away}!"
        next
      end

      result_arr = @conn.query("select matchinfono from results where matchinfono='#{matchinfono}'")

      if  result_arr.num_rows == 0
        puts "Result date[#{match_date}] of matchinfono:#{matchinfono}, #{match_name},#{home}:#{away} not exist!"
        next
      end

      #next

      puts matchinfono

      company_tables.each_with_index do |company, index|
        unless peilv_arr[index].nil?
          if /[\d]/.match(peilv_arr[index])
            pellv_company =  peilv_arr[index].split(",")

            changeid = pellv_company[0].to_i
            initrate = pellv_company[1].to_f
            finrate = pellv_company[2].to_f
            level1 = pellv_company[3].to_f
            level2 = pellv_company[4].to_f

            result = 0

            if direction == 1
              direct = 1
            elsif direction == 2
              direct = -1
            else
              puts "Error direction(#{direction}) date[#{match_date}] of matchinfono:#{matchinfono}"
            end

            result = HuuuuntUtil.calc_rate_result(finrate*direct, goal1, goal2)

            # 变换
            initrate = (initrate*4).to_i
            finrate = (finrate*4).to_i
            level1 = (level1*1000).to_i
            level2 = (level2*1000).to_i

            sql = "insert into #{company} (matchinfono, matchdt, matchno, team1no, team2no, initrate, finrate,
                                                  uplevel, downlevel, result, halfgoal1, halfgoal2,
                                                  goal1, goal2, direction)
                 values ('#{matchinfono}','#{match_date}', #{match_no}, #{team1no}, #{team2no}, #{initrate}, #{finrate},
                          #{level1}, #{level2}, #{result}, #{halfgoal1}, #{halfgoal2}, #{goal1}, #{goal2}, #{direct})"
            odd_arr = @conn.query("select matchinfono from #{company} where matchinfono='#{matchinfono}'")
            if odd_arr.num_rows == 0
              #puts sql
              @conn.query(sql)
            else
              sql = "update #{company} set matchdt='#{match_date}', matchno=#{match_no},
                    team1no=#{team1no}, team2no=#{team2no}, initrate=#{initrate}, finrate=#{finrate},
                    uplevel=#{level1}, downlevel=#{level2}, result=#{result}, halfgoal1=#{halfgoal1},
                    halfgoal2=#{halfgoal2}, goal1=#{goal1}, goal2=#{goal2}, direction=#{direct} where matchinfono='#{matchinfono}'"
              #puts sql
              @conn.query(sql)
            end
          end
        end
      end
    end
    commit()
  end

  def add_new_match_and_team_info
    @@new_matchs.each do |match|
      new_match_id = get_max_match_id()+1
      @conn.query("insert into match_infos (match_id, name_cn, match_color, is_stat)
                 values (#{new_match_id}, '#{match[:match_name]}', '#{match[:match_color]}', 0)")
      @@orginal_match_map[match[:match_name]] = [new_match_id, 0]
    end

    @@new_teams.each do |team|
      new_team_id = get_max_team_id()+1
      insert_team_infos(new_team_id, team[:team_name], @@orginal_match_map[team[:match_name]])
      @@orginal_team_map[team[:team_name]] = new_team_id
    end
    commit()
  end

  def should_stop_update
    return @@new_matchs.size > 0 || @@new_teams.size > 0
  end

  def display_new_match_info
    puts "match need to add begin ====\n"
    @@new_matchs.each do |match|
      puts "#{match[:match_date]}: #{match[:match_name]}, #{match[:match_color]}"
    end
    puts "match need to add end ====\n"
  end

  def display_new_team_info

    puts "team need to add begin ====\n"
    @@new_teams.each do |team|
      puts "#{team[:match_date]}: #{team[:match_name]}, #{team[:team_name]}"
    end
    puts "team need to add end ====\n"

  end

  def display_new_match_and_team_info

    puts "match need to add begin ====\n"
    @@new_matchs.each do |match|
      puts "#{match[:match_date]}: #{match[:match_name]}, #{match[:match_color]}"
    end
    puts "match need to add end ====\n"

    puts "team need to add begin ====\n"
    @@new_teams.each do |team|
      puts "#{team[:match_date]}: #{team[:match_name]}, #{team[:team_name]}"
    end
    puts "team need to add end ====\n"
  end

  def add_new_match(match_name, match_color, match_date)
    @@new_matchs.push({:match_name=>match_name, :match_color=>match_color, :match_date=>match_date})
    @@new_match_map[match_name] = match_color
  end

  def add_new_team(match_name, team_name, match_date)
    @@new_teams.push({:match_name=>match_name, :team_name=>team_name, :match_date=>match_date})
    @@new_team_map[team_name] = match_name
  end

  def is_match_stat(match_name)
    if @@orginal_match_map.has_key?(match_name)
      return @@orginal_match_map[match_name][1].to_i
    end
    return 2
  end

  def is_team_stat(team_id)
    if @@stat_teams.has_key?(team_id.to_i)
      return 1
    end
    return 0
  end

  def is_match_exist(match_name)
    return @@orginal_match_map.has_key?(match_name)
  end

  def is_team_exist(team_name)
    return @@orginal_team_map.has_key?(team_name)
  end

  def is_match_new_exist(match_name)
    return @@new_match_map.has_key?(match_name)
  end

  def is_team_new_exist(team_name)
    return @@new_team_map.has_key?(team_name)
  end

  def init_match_map
    # 赛事名称匹配，目前仅使用表match_infos中的name_cn字段，以及match_other_infos中的name字段
    @@orginal_match_map = {}

    match_arr = @conn.query("select match_id, is_stat, name_cn from match_infos")

    match_arr.each_hash do |per_match_id|
      @@orginal_match_map[per_match_id['name_cn']] = [per_match_id['match_id'], per_match_id['is_stat']];
    end

    match_arr = @conn.query("select distinct is_stat,match_other_infos.match_id,match_other_infos.name from match_other_infos left join match_infos on match_infos.match_id = match_other_infos.match_id")

    match_arr.each_hash do |per_match_id|
      @@orginal_match_map[per_match_id['name']] = [per_match_id['match_id'], per_match_id['is_stat']];
    end
  end

  def init_team_map
    # 球队名称匹配，目前仅使用表team_infos中的name_cn字段，以及team_other_infos中的name字段
    @@orginal_team_map = {}

    team_arr = @conn.query("select team_id,name_cn from team_infos")

    team_arr.each_hash do |team|
      @@orginal_team_map[team['name_cn']] = team['team_id'];
    end

    team_arr = @conn.query("select team_id,name from team_other_infos")

    team_arr.each_hash do |other_team|
      @@orginal_team_map[other_team['name']] = other_team['team_id'];
    end
  end

  def init_multi_match_name
    @@multi_match_map = {}

    match_arr = @conn.query("select match_id, name_cn, name_tc, name_en, match_color from match_infos")
    match_arr.each_hash do |item|
      @@multi_match_map[item['match_id'].to_i] = [item['name_cn'], item['name_tc'], item['name_en'], item['match_color']]
      #puts "#{item['match_id']} => #{@@multi_match_map[item['match_id']]}"
    end
  end

  def init_multi_team_name
    @@multi_team_map = {}

    team_arr = @conn.query("select team_id, name_cn, name_tc, name_en, match_id from team_infos")
    team_arr.each_hash do |item|
      @@multi_team_map[item['team_id'].to_i] = [item['name_cn'], item['name_tc'], item['name_en'], item['match_id']]
    end
  end

  def add_name_to_match_other_infos(match_id, match_name)
    @conn.query("insert into match_other_infos (match_id, name)
                                        values (#{match_id}, '#{match_name}')")
  end

  def add_name_to_team_other_infos(team_id, team_name, match_id)
    @conn.query("insert into team_other_infos (team_id, name, match_id)
                                       values (#{team_id}, '#{team_name}', #{match_id})")
  end

  def add_multi_name_to_match_infos(match_id, name_cn, name_tn, name_en, match_color)
    @conn.query("update match_infos set name_cn='#{name_cn}', name_tc='#{name_tn}',
                                        name_en=\"#{name_en}\", match_color='#{match_color}'
                                  where match_id=#{match_id}")
  end

  def add_multi_name_to_team_infos(team_id, name_cn, name_tn, name_en)
    @conn.query("update team_infos set name_cn='#{name_cn}', name_tc='#{name_tn}',
                                       name_en=\"#{name_en}\"
                                 where team_id=#{team_id}")
  end

  def add_multi_name_to_global_match_buffer(match_id, name_cn, name_tn, name_en, match_color)
    @@multi_match_map[match_id] = [name_cn, name_tn, name_en, match_color]
  end

  def add_multi_name_to_global_team_buffer(team_id, name_cn, name_tn, name_en, match_id)
    @@multi_team_map[team_id] = [name_cn, name_tn, name_en, match_id]
  end

  def deal_multi_match_name(multi_match_name)
    multi_match_name.each do |data|
      name_cn = data[:name_cn]
      name_tn = data[:name_tn]
      name_en = data[:name_en]
      color = data[:color]
      #puts "#{Iconv.iconv("GBK", "UTF-8", name_cn)}, #{Iconv.iconv("GBK", "UTF-8", name_tn)}, #{name_en}, #{color}"
      # 如果简体中文名和繁体中文名，其中有一个在数据库中存在
      # 如果简体中文名和繁体中文名在数据库中都不存在，则不处理
      if is_match_exist(name_cn) || is_match_exist(name_tn)
        # 获取赛事ID
        match_id = 0
        if is_match_exist(name_cn)
          match_id = @@orginal_match_map[name_cn][0].to_i
        end
        if is_match_exist(name_tn)
          match_id = @@orginal_match_map[name_tn][0].to_i
        end
        #puts "match_id #{match_id}"
        # 获取该赛事已有的简体中文名、繁体中文名、英文名和显示用color
        old_name_cn = @@multi_match_map[match_id][0]
        old_name_tn = @@multi_match_map[match_id][1]
        old_name_en = @@multi_match_map[match_id][2]
        old_color = @@multi_match_map[match_id][3]

        # 如果繁体中文名和英文名为空，仅判断繁体中文名即可
        # 比较简体中文名和name_cn是否相同
        # 如果相同，则无动作；如果不同，则将原有的简体中文名写到match_other_infos中
        # 再将新读取的简体、繁体中文和英文名写入到match_infos中
        if old_name_tn==nil || old_name_tn.size==0
          # 因为name_cn要覆盖od_name_cn的位置，所以要先把old_name_cn保存到match_other_infos中
          if old_name_cn != name_cn
            puts "move old match name [#{name_cn}]"
            add_name_to_match_other_infos(match_id, old_name_cn)
          end
          # name_cn无需判断存在和插入数据库，因为namc_cn字段不仅用于显示，同时也用作数据匹配
          if !is_match_exist(name_tn) && name_tn!=old_name_cn
            puts "add new match name [#{name_tn}]"
            add_name_to_match_other_infos(match_id, name_tn)
          end
          puts "add new match name_cn, name_tn #{name_cn}, #{name_tn}"
          # 为避免重复写入数据库同样的数据，在@@multi_match_map中更新
          add_multi_name_to_global_match_buffer(match_id, name_cn, name_tn, name_en, color)
          # 写入数据库
          add_multi_name_to_match_infos(match_id, name_cn, name_tn, name_en, color)
        end
      end
    end
  end

  def deal_multi_team_name(multi_team_name)
    multi_team_name.each do |data|
      name_cn = data[:name_cn]
      name_tn = data[:name_tn]
      name_en = data[:name_en]
      #puts "#{Iconv.iconv("GBK", "UTF-8", name_cn)}, #{Iconv.iconv("GBK", "UTF-8", name_tn)}, #{name_en}"
      # 如果简体中文名和繁体中文名，其中有一个在数据库中存在
      # 如果简体中文名和繁体中文名在数据库中都不存在，则不处理
      if is_team_exist(name_cn) || is_team_exist(name_tn)
        # 获取球队ID
        team_id = 0
        if is_team_exist(name_cn)
          team_id = @@orginal_team_map[name_cn].to_i
        end
        if is_team_exist(name_tn)
          team_id = @@orginal_team_map[name_tn].to_i
        end
        #puts "team_id #{team_id}"
        # 获取该赛事已有的简体中文名、繁体中文名、英文名
        old_name_cn = @@multi_team_map[team_id][0]
        old_name_tn = @@multi_team_map[team_id][1]
        old_name_en = @@multi_team_map[team_id][2]
        match_id = @@multi_team_map[team_id][3]
        # 如果繁体中文名和英文名为空，仅判断繁体中文名即可
        # 比较简体中文名和name_cn是否相同
        # 如果相同，则无动作；如果不同，则将原有的简体中文名写到team_other_infos中
        # 再将新读取的简体、繁体中文和英文名写入到team_infos中
        if old_name_tn==nil || old_name_tn.size==0
          if old_name_cn != name_cn
            puts "move old team name [#{old_name_cn}]"
            add_name_to_team_other_infos(team_id, old_name_cn, match_id)
          end
          # name_cn无需判断存在和插入数据库，只需处理name_tn
          if !is_team_exist(name_tn) && name_tn!=old_name_cn
            puts "add new team name [#{name_tn}]"
            add_name_to_team_other_infos(team_id, name_tn, match_id)
          end
          puts "add new team name_cn, name_tn #{name_cn}, #{name_tn}"
          # 为避免重复写入数据库同样的数据，在@@multi_team_map中更新
          add_multi_name_to_global_team_buffer(team_id, name_cn, name_tn, name_en, match_id)
          # 写入数据库
          add_multi_name_to_team_infos(team_id, name_cn, name_tn, name_en)
        end
      end
    end
  end

  def commit
    @conn.query("commit")
  end

  def truncate_table(table_name)
    @conn.query("truncate table #{table_name}")
  end

  def close
    @conn.close
  end

  def truncate_table_match_infos
    @conn.query("truncate table match_infos")
  end

  def insert_match_infos(match_id, match_name, name_tn, name_en, name_jp,
          match_color, is_stat, country_id,
          bet007_match_id, phases, season_type)
    sql = "insert into match_infos (match_id, name_cn, name_tc, name_en,
                                          name_jp, match_color, is_stat,
                                          country_id, bet007_match_id, phases, season_type)
                 values (#{match_id.to_i}, '#{match_name}', '#{name_tn}', \"#{name_en}\",
                         '#{name_jp}', '#{match_color}', #{is_stat}, #{country_id},
                         #{bet007_match_id}, #{phases}, #{season_type})"
    #puts "#{sql}"
    @conn.query(sql)
  end

  def truncate_table_match_other_infos
    @conn.query("truncate table match_other_infos")
  end

  def insert_match_other_infos(match_id, match_name)
    @conn.query("insert into match_other_infos (match_id, name)
                 values (#{match_id}, '#{match_name}')")
  end

  def truncate_table_team_infos
    @conn.query("truncate table team_infos")
  end

  def insert_team_infos(team_id, team_name, match_id, team_tn, team_en, team_jp)
    @conn.query("insert into team_infos (team_id, name_cn, match_id, name_tc, name_en, name_jp)
                 values (#{team_id}, '#{team_name}', #{match_id}, '#{team_tn}', \"#{team_en}\", '#{team_jp}')")
  end

  def truncate_table_team_other_infos
    @conn.query("truncate table team_other_infos")
  end

  def insert_team_other_infos(team_id, team_name, match_id)
    @conn.query("insert into team_other_infos (team_id, name, match_id)
                 values (#{team_id}, '#{team_name}', #{match_id})")
  end

  def get_match_id_by_match_name(match_name)
    match_id = 0
    match_id_arr = @conn.query("select match_id from match_infos where name_cn='#{match_name}'")
    if match_id_arr.num_rows == 0
      match_id_arr = @conn.query("select match_id from match_other_infos where name='#{match_name}'")
    end
    if match_id_arr.num_rows > 1
      puts "match name(#{match_name}) duplicate! "
    end
    if match_id_arr.num_rows == 0
      puts "match name(#{match_name}) does not exist! "
      return match_id
    end
    match_id_arr.each_hash do |per_match_id|
      match_id = per_match_id['match_id']
    end
    #puts "match_id = #{match_id}"
    match_id
  end

  def get_team_id_by_team_name(team_name)
    team_id = 0
    team_id_arr = @conn.query("select team_id from team_infos where name_cn='#{team_name}'")
    if team_id_arr.num_rows == 0
      team_id_arr = @conn.query("select team_id from team_other_infos where name='#{team_name}'")
    end
    if team_id_arr.num_rows > 1
      puts "team name(#{team_name}) duplicate! "
    end
    if team_id_arr.num_rows == 0
      puts "team name(#{team_name}) does not exist! "
      return team_id
    end
    team_id_arr.each do |item|
      team_id = item[0]
      break
    end
    return team_id
  end

  def get_all_match_infos
    @conn.query("select match_id, name_cn, name_tc, name_en, name_jp, match_color, is_stat,
                        country_id, bet007_match_id, phases, season_type
                 from match_infos")
  end

  def get_all_match_other_infos
    # 必须使用order by match_id，因为在写入excel时，需要确保读取的同一个match_id对应的多个赛事名字必须连续
    @conn.query("select match_id, name from match_other_infos order by match_id, id")
  end

  def get_all_team_infos
    @conn.query("select t.team_id, t.name_cn, t.name_tc, t.name_en, t.name_jp,
                        t.match_id, m.name_cn FROM team_infos t
                 left join match_infos m on t.match_id = m.match_id")
  end

  def get_all_team_other_infos
    # 必须使用order by team_id，因为在写入excel时，需要确保读取的同一个team_id对应的多个球队名字必须连续
    @conn.query("select team_id, name from team_other_infos order by team_id, id")
  end

  def country_is_not_exist?(country)
    countries = @conn.query("select * from countries where name_cn='#{country}'")
    if countries.num_rows > 0
      return false
    end
    return true
  end

  def insert_country(country)
    @conn.query("insert into countries (name_cn) value ('#{country}')")
  end

  def get_country_id_by_name(country)
    country_id = 0
    countries = @conn.query("select * from countries where name_cn='#{country}'")
    if countries.num_rows==0 || countries.num_rows>1
      puts "Error: #{country} has #{countries.num_rows} countries."
    end
    countries.each do |item|
      country_id = item[0]
    end
    return country_id
  end

  def get_country_name_by_id(country_id)
    #puts "country_id = #{country_id}"
    return "" if country_id==0
    country_name = ""
    countries = @conn.query("select id, name_cn from countries where id=#{country_id}")
    if countries.num_rows==0 || countries.num_rows>1
      puts "Error: #{country_id} has #{countries.num_rows} countries."
    end
    countries.each do |item|
      country_name = item[1]
    end
    return country_name
  end

  # 获取要更新赛果数据的起始日期
  def get_result_latest_date()
    latest_date_arr = @conn.query("select max(matchdt) from results")
    latest_date_arr.each do |item|
      # 如果最近的日期时间值在8点之后，则要取下一天作为起始日期
      latest_datetime = item[0]
      #puts "#{latest_datetime}"
      tmp = latest_datetime.split
      # 获取最近日期
      latest_date = tmp[0]
      #puts "#{latest_date}"
      # 获取最近日期的下一个日期
      next_date = Date.parse(latest_date).succ
      std_datetime = latest_date + " 08:00:00"
      # puts "#{latest_datetime}, #{std_datetime}"
      if (Time.parse(latest_datetime) - Time.parse(std_datetime)) > 0
        return next_date
      else
        return latest_date
      end
    end
  end

  # 获取要更新亚洲赔率数据的起始日期
  def get_asia_latest_date
    # 获取数据库中ysb_asias最新赛事日期的后一天，作为起始日期
    latest_date_arr = @conn.query("select max(matchdt) from ysb_asias")
    latest_date_arr.each do |item|
      latest_datetime = item[0]
      tmp = latest_datetime.split
      latest_date = tmp[0]
      next_date = Date.parse(latest_date).succ
      return next_date
    end
  end

  # 获取要更新欧洲赔率数据的起始日期
  def get_europe_latest_date
    # 获取数据库中ysb_europes最新赛事日期的后一天，作为起始日期
    latest_date_arr = @conn.query("select max(matchdt) from ysb_europes")
    latest_date_arr.each do |item|
      latest_datetime = item[0]
      tmp = latest_datetime.split
      latest_date = tmp[0]
      next_date = Date.parse(latest_date).succ
      return next_date
    end
  end

  # 获取要统计的赛事信息，包括“bet007_match_id”，“phases”，“season_type”，“new season”
  def get_match_season_info(season_type)
    return @conn.query("SELECT m.match_id, m.name_cn, m.bet007_match_id,
                               m.phases, m.season_type
                        FROM match_infos m
                        where m.phases>0 and m.season_type=#{season_type}")
  end

  def get_special_match_season_info(season_type, match_str)
    return @conn.query("select match_id, name_cn, bet007_match_id, phases, season_type
                        from match_infos
                        where phases>0 and season_type=#{season_type} and match_id in (#{match_str})")
  end

  # 判断赛事名称在数据库中是否存在
  def is_match_name_exist?(match_name)
    match_arr = @conn.query("select match_id from match_infos where name_cn='#{match_name}'")
    if match_arr.num_rows == 0
      match_arr = @conn.query("select match_id from match_other_infos where name='#{match_name}'")
    end
    if match_arr.num_rows == 0
      return false
    end
    return true
  end

  # 判断球队名称在数据库中是否存在
  def is_team_name_exist?(team_name)
    team_arr = @conn.query("select team_id from team_infos where name_cn='#{team_name}'")
    if team_arr.num_rows == 0
      team_arr = @conn.query("select team_id from team_other_infos where name='#{team_name}'")
    end
    if team_arr.num_rows == 0
      return false
    end
    return true
  end

  def is_match_exist?(matchinfono)
    result_set = @conn.query("select matchinfono from results where matchinfono='#{matchinfono}'")
    if result_set.num_rows > 1
      puts "matchinfono[#{matchinfono}] in table 'results' has duplicated! "
    end
    if result_set.num_rows == 0
      return false
    end
    return true
  end

  def is_match_need_stat?(match_name_utf8)
    match_id = get_match_id_by_match_name(match_name_utf8)
    #puts "Get Match id #{match_id}"
    return false if match_id == 0
    ret_set = @conn.query("select is_stat from match_infos where match_id=#{match_id}")
    if ret_set.num_rows==0 || ret_set.num_rows>1
      puts "Error info about match_id #{match_id}"
    end
    is_stat = 0
    ret_set.each do |item|
      is_stat = item[0]
    end
    #puts "is_stat class = #{is_stat.class}"
    if is_stat.to_i==1
      return true
    end
    return false
  end

  def insert_or_update_results(matchinfono, match_dt, match_id, team1_id, team2_id,
          h_goal1, h_goal2, goal1, goal2, status)
    records = @conn.query("select * from results where matchinfono='#{matchinfono}'")
    if records.num_rows == 0      
      @conn.query("insert into results (matchinfono, matchdt, matchno, team1no, team2no,
                                      halfgoal1, halfgoal2, goal1, goal2, status)
                             values ('#{matchinfono}', '#{match_dt}', #{match_id},
                                     #{team1_id}, #{team2_id}, #{h_goal1}, #{h_goal2},
                                     #{goal1}, #{goal2}, #{status})")
    else
      @conn.query("update results set matchdt='#{match_dt}', matchno=#{match_id},
                                      team1no=#{team1_id}, team2no=#{team2_id},
                                      halfgoal1=#{h_goal1}, halfgoal2=#{h_goal2}, 
                                      goal1=#{goal1}, goal2=#{goal2}, status=#{status}
                                  where matchinfono='#{matchinfono}'")
    end
  end

  def get_max_match_id
    max_match_id = 0
    ret_arr = @conn.query("select max(match_id) from match_infos")
    ret_arr.each do |item|
      max_match_id = item[0]
    end
    return max_match_id.to_i
  end

  def get_max_team_id
    max_team_id = 0
    ret_arr = @conn.query("select max(team_id) from team_infos")
    ret_arr.each do |item|
      max_team_id = item[0]
    end
    return max_team_id.to_i
  end

  def is_matches_exist?(match_year, phase, match_id, team1_id, team2_id)
    match_arr = @conn.query("select * from matches where matchyear='#{match_year}' and
                                             phase=#{phase} and
                                             matchno=#{match_id} and
                                             team1no=#{team1_id} and
                                             team2no=#{team2_id}")
    if match_arr.num_rows==0
      return false
    end
    return true
  end

  def insert_base_matches(match_year, phase, match_id, match_datetime, team1_id, team2_id)
    @conn.query("insert into matches (matchyear, phase, matchdt, matchno, team1no, team2no)
                              values ('#{match_year}', #{phase}, '#{match_datetime}',
                                      #{match_id}, #{team1_id}, #{team2_id})")
  end

  # start_date应从指定day的08:00:00 -> day+1的07:59:59
  def get_results_by_matchno_daterange(match_id, start_date, end_date)
    @conn.query("select matchdt, matchno, team1no, team2no, halfgoal1, halfgoal2, goal1, goal2 from results
                 where matchdt>='#{start_date} 08:00:00' and matchdt<='#{end_date} 07:59:59' and
                       matchno=#{match_id} and status=1
                 order by matchdt")
  end

  def is_this_result_exist_in_matches?(match_year, matchno, team1no, team2no)
    match_arr = @conn.query("select * from matches where matchyear='#{match_year}' and matchno=#{matchno} and
                                             team1no=#{team1no} and team2no=#{team2no}")
    if match_arr.num_rows==0
      return false
    end
    return true
  end

  def get_special_matches(match_year, matchno, team1no, team2no)
    @conn.query("select id,flag from matches where matchyear='#{match_year}' and matchno=#{matchno} and
                                             team1no=#{team1no} and team2no=#{team2no} order by phase")
  end

  def update_special_matches(id, matchdt, halfgoal1, halfgoal2, goal1, goal2, flag)
    @conn.query("update matches set matchdt='#{matchdt}', halfgoal1=#{halfgoal1},
                                    halfgoal2=#{halfgoal2}, goal1=#{goal1}, 
                                    goal2=#{goal2}, flag=#{flag}
                            where id=#{id}")
  end

  def get_finished_matches(match_year, match_id)
    @conn.query("select phase,team1no,team2no,halfgoal1,halfgoal2,goal1,goal2
                   from matches
                  where matchyear='#{match_year}' and matchno=#{match_id} and flag=1 order by matchdt desc")
  end

  def get_distinct_teams(match_year, match_id)
    @conn.query("select distinct team1no from matches
                 where matchyear='#{match_year}' and matchno=#{match_id}")
  end

  def deal_scores_all(matchno, matchyear, teamno,
          score, matchcnt, wincnt, deucecnt, losscnt, wingoal, lossgoal, goal,
          score6, matchcnt6, wincnt6, deucecnt6, losscnt6, wingoal6, lossgoal6, goal6,
          scoreH, matchcntH, wincntH, deucecntH, losscntH, wingoalH, lossgoalH, goalH,
          scoreA, matchcntA, wincntA, deucecntA, losscntA, wingoalA, lossgoalA, goalA,
          history6)
    score_arr = @conn.query("select id from scores where matchno=#{matchno} and
                                                         matchyear='#{matchyear}' and
                                                         teamno=#{teamno}")
    if score_arr.num_rows == 0
      @conn.query("insert into scores (matchno, matchyear, teamno,
                      score, matchcnt, wincnt, deucecnt, losscnt, wingoal, lossgoal, goal,
                      score6, matchcnt6, wincnt6, deucecnt6, losscnt6, wingoal6, lossgoal6, goal6,
                      scoreH, matchcntH, wincntH, deucecntH, losscntH, wingoalH, lossgoalH, goalH,
                      scoreA, matchcntA, wincntA, deucecntA, losscntA, wingoalA, lossgoalA, goalA,
                      history6)
                   values (#{matchno}, '#{matchyear}', #{teamno},
                      #{score}, #{matchcnt}, #{wincnt}, #{deucecnt}, #{losscnt}, #{wingoal}, #{lossgoal}, #{goal},
                      #{score6}, #{matchcnt6}, #{wincnt6}, #{deucecnt6}, #{losscnt6}, #{wingoal6}, #{lossgoal6}, #{goal6},
                      #{scoreH}, #{matchcntH}, #{wincntH}, #{deucecntH}, #{losscntH}, #{wingoalH}, #{lossgoalH}, #{goalH},
                      #{scoreA}, #{matchcntA}, #{wincntA}, #{deucecntA}, #{losscntA}, #{wingoalA}, #{lossgoalA}, #{goalA},
                      '#{history6}')")
    elsif score_arr.num_rows == 1
      @conn.query("update scores set score=#{score}, matchcnt=#{matchcnt}, wincnt=#{wincnt},
                      deucecnt=#{deucecnt}, losscnt=#{losscnt}, wingoal=#{wingoal},
                      lossgoal=#{lossgoal}, goal=#{goal},
                      score6=#{score6}, matchcnt6=#{matchcnt6}, wincnt6=#{wincnt6},
                      deucecnt6=#{deucecnt6}, losscnt6=#{losscnt6}, wingoal6=#{wingoal6},
                      lossgoal6=#{lossgoal6}, goal6=#{goal6},
                      scoreH=#{scoreH}, matchcntH=#{matchcntH}, wincntH=#{wincntH},
                      deucecntH=#{deucecntH}, losscntH=#{losscntH}, wingoalH=#{wingoalH},
                      lossgoalH=#{lossgoalH}, goalH=#{goalH},
                      scoreA=#{scoreA}, matchcntA=#{matchcntA}, wincntA=#{wincntA},
                      deucecntA=#{deucecntA}, losscntA=#{losscntA}, wingoalA=#{wingoalA}, 
                      lossgoalA=#{lossgoalA}, goalA=#{goalA},
                      history6='#{history6}'
                   where matchno=#{matchno} and matchyear='#{matchyear}' and teamno=#{teamno}")
    elsif score_arr.num_rows > 1
      puts "#{matchyear},#{matchno},#{teamno} score has error info!"
    end
  end

  def get_scores_all_by_season(match_id, match_year)
    @conn.query("select teamno,score-point,matchcnt,wincnt,deucecnt,losscnt,wingoal,lossgoal,goal
                 from scores where matchno=#{match_id} and matchyear='#{match_year}'
                 order by score-point desc, goal desc, wingoal desc, wincnt desc, deucecnt desc, matchcnt")
  end

  def get_scores_home_by_season(match_id, match_year)
    @conn.query("select teamno,scoreH,matchcntH,wincntH,deucecntH,losscntH,wingoalH,lossgoalH,goalH
                 from scores where matchno=#{match_id} and matchyear='#{match_year}'
                 order by scoreH desc, goalH desc, wingoalH desc, wincntH desc, deucecntH desc, matchcntH")
  end

  def get_scores_away_by_season(match_id, match_year)
    @conn.query("select teamno,scoreA,matchcntA,wincntA,deucecntA,losscntA,wingoalA,lossgoalA,goalA
                 from scores where matchno=#{match_id} and matchyear='#{match_year}'
                 order by scoreA desc, goalA desc, wingoalA desc, wincntA desc, deucecntA desc, matchcntA")
  end

  def get_scores_6_by_season(match_id, match_year)
    @conn.query("select teamno,score6,matchcnt6,wincnt6,deucecnt6,losscnt6,wingoal6,lossgoal6,goal6
                 from scores where matchno=#{match_id} and matchyear='#{match_year}'
                 order by score6 desc, goal6 desc, wingoal6 desc, wincnt6 desc, deucecnt6 desc, matchcnt6")
  end

  def get_need_modify_result_by_teamno(old_teamno)
    @conn.query("select * from results where team1no=#{old_teamno} or team2no=#{old_teamno}")
  end

  def update_results_by_teamno(id, matchinfono, team1no, team2no)
    @conn.query("update results set matchinfono='#{matchinfono}', team1no=#{team1no}, team2no=#{team2no}
                          where id=#{id}")
  end

  def get_need_modify_match_by_teamno(old_teamno)
    @conn.query("select * from matches where team1no=#{old_teamno} or team2no=#{old_teamno}")
  end

  def update_matches_by_teamno(id, team1no, team2no)
    @conn.query("update matches set team1no=#{team1no}, team2no=#{team2no} where id=#{id}")
  end

  def update_scores_by_teamno(old_teamno, new_teamno)
    @conn.query("update scores set teamno=#{new_teamno} where teamno=#{old_teamno}")
  end

  def add_columns_to_europe_tables(company)
    @conn.query("alter table #{company} add column changeid int(11), add column home varchar(255), add column away varchar(255)")
  end

  def add_index_matchinfono_to_tables(table_name)
    @conn.query("create index i_matchinfono on #{table_name} (matchinfono(255))")
  end

  def truncate_rank_changes
    @conn.query("truncate rank_changes;")
    @conn.query("commit")
  end

  def insert_rank_changes
    match_arr = @conn.query("select matchyear, phase, matchdt, matchno, team1no, team2no, goal1, goal2 from matches order by matchyear asc, matchno asc, phase asc")
    match_arr.each do |match|
      matchyear = match[0]
      phase = match[1]
      matchdt = match[2]
      matchno = match[3]
      team1no = match[4]
      team2no = match[5]
      goal1 = match[6]
      goal2 = match[7]
      if goal1.nil?
        next
      end
      team1_goal = goal1.to_i - goal2.to_i
      team2_goal = goal2.to_i - goal1.to_i
      team1_score = team1_goal == 0 ? 1 : team1_goal < 0 ? 0 : 3
      team2_score = team2_goal == 0 ? 1 : team2_goal < 0 ? 0 : 3
      if matchdt.nil?
        insert_team1_sql = "insert into rank_changes(matchno, matchyear, teamno, phase, score, goal, wingoal, matchdt) values(#{matchno}, '#{matchyear}', #{team1no}, #{phase}, #{team1_score}, #{team1_goal}, #{goal1}, NULL)"
        insert_team2_sql = "insert into rank_changes(matchno, matchyear, teamno, phase, score, goal, wingoal, matchdt) values(#{matchno}, '#{matchyear}', #{team2no}, #{phase}, #{team2_score}, #{team2_goal}, #{goal2}, NULL)"
      else
        insert_team1_sql = "insert into rank_changes(matchno, matchyear, teamno, phase, score, goal, wingoal, matchdt) values(#{matchno}, '#{matchyear}', #{team1no}, #{phase}, #{team1_score}, #{team1_goal}, #{goal1}, '#{matchdt}')"
        insert_team2_sql = "insert into rank_changes(matchno, matchyear, teamno, phase, score, goal, wingoal, matchdt) values(#{matchno}, '#{matchyear}', #{team2no}, #{phase}, #{team2_score}, #{team2_goal}, #{goal2}, '#{matchdt}')"
      end
      puts insert_team1_sql
      puts insert_team2_sql
      @conn.query(insert_team1_sql)
      @conn.query(insert_team2_sql)
    end
    @conn.query("commit")
  end

  def update_rank_changes
    rank_arr = @conn.query("select matchyear, matchno, max(phase) from rank_changes group by matchyear, matchno")
    rank_arr.each do |rank_tmp|
      matchyear = rank_tmp[0]
      matchno = rank_tmp[1]
      maxphase = rank_tmp[2].to_i
      for phase in 1..maxphase
        team_arr = @conn.query("select teamno from  rank_changes where matchyear = '#{matchyear}' and matchno = #{matchno} and phase  <= #{phase} group by teamno order by sum(score) desc, sum(goal) desc, sum(wingoal) desc")
        i = 1
        team_arr.each do|teamno|
          upate_rank_sql = "update rank_changes set rank = #{i} where matchyear='#{matchyear}' and matchno=#{matchno} and phase=#{phase} and teamno=#{teamno}"
          puts upate_rank_sql
          @conn.query(upate_rank_sql)
          i = i + 1
        end
      end
    end
    @conn.query("commit")
  end

  def get_teams_by_match_year(match, match_year)
    @conn.query("select distinct team1no from matches where matchno=#{match} and matchyear='#{match_year}' order by team1no;")
  end

  def get_asia_history_by_year_match_team(company, start_date, end_date, match_no, team_no, desc)
    @conn.query("SELECT * FROM #{company}  where matchno=#{match_no} and matchdt>'#{start_date}' and matchdt<'#{end_date}'
                          and (team1no=#{team_no} or team2no=#{team_no}) order by matchdt #{desc};")
  end

  def truncate_asia_stat_data_by_date(date_str)
    @conn.query("delete from asia_type_one_stats where statdt='#{date_str}'")
  end

  def insert_asia_stat_data_type_one(date, match_no, team_no, count, result, stat_data_str)
    @conn.query("insert into asia_type_one_stats (statdt, matchno, teamno, count, result, matches)
                         values ('#{date}', #{match_no}, #{team_no}, #{count}, #{result}, '#{stat_data_str}')")
  end

  def truncate_asia_year_stat_by_match_year(match_no, match_year)
    @conn.query("delete from asia_type_one_year_stats where matchno=#{match_no} and match_year='#{match_year}'")
    @conn.query("delete from asia_type_one_year_stat_details where matchno=#{match_no} and match_year='#{match_year}'")
  end

  def insert_asia_year_stat_detail_data_type_one(match_year, match_no, team_no, count, result, matches)
    @conn.query("insert into asia_type_one_year_stat_details (match_year, matchno, teamno, count, result, matches)
                         values ('#{match_year}', #{match_no}, #{team_no}, #{count}, #{result}, '#{matches}')")
  end

  def insert_asia_year_stat_data_type_one(match_year, match_no, count_key, result, count)
    @conn.query("insert into asia_type_one_year_stats (match_year, matchno, count_key, result, count)
                         values ('#{match_year}', #{match_no}, #{count_key}, #{result}, #{count})")
  end

  def insert_or_update_scorepoint(season, match_id, team_id, reason_utf8, point)
    score_points = @conn.query("select * from score_others where match_year='#{season}' and
                                                  match_id=#{match_id} and
                                                  team_id=#{team_id}")
    if score_points.num_rows == 0
      sql = "insert into score_others (match_year, match_id, team_id, reason, point) 
                               values ('#{season}', #{match_id}, #{team_id}, '#{reason_utf8}', #{point})"
      @conn.query(sql)
    else
      sql = "update score_others set reason='#{reason_utf8}', point=#{point}
                               where match_year='#{season}' and match_id=#{match_id} and team_id=#{team_id}"
      @conn.query(sql)
    end
  end

  def get_score_points(season, match_id)
    @conn.query("select * from score_others where match_year='#{season}' and match_id=#{match_id}")
  end

  def update_score_point(season, match_id, team_id, point)
    sql = "update scores set point=#{point}
                       where matchyear='#{season}' and matchno=#{match_id} and teamno=#{team_id}"
    @conn.query(sql)
  end

end