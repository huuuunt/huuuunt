require 'match_info_load'
require 'team_info_load'
require 'match_info_output'
require 'team_info_output'
require 'result_update'
require 'asia_update'
require 'europe_update'
require 'matches_update'
require 'result_matches'
require 'score'
require 'scores_compare'
require 'result_modify'
require 'match_modify'
require 'score_modify'
require 'europe_modify'
require 'asia_modify'
require 'rank_update'
require 'asia_stat_update'
require 'asia_stat_year_update'
require 'score_point'

# 赛季跨年的赛事ID
FIX_MATCHES_TYPE1 = [
  1,    # 英超
  2,    # 英冠
  9,    # 意甲
  10,   # 意乙
  18,   # 西甲
  19,   # 西乙
  24,   # 德甲
  25,   # 德乙
  28,   # 法甲
  29,   # 法乙
  32,   # 葡超
  34,   # 苏超
  38,   # 荷甲
  40,   # 比甲
  62,   # 丹麦超
  69    # 奥甲
]

# 赛季不跨年的赛事ID
FIX_MATCHES_TYPE2 = [
  42,   # 瑞典超
  54,   # 芬超
  56,   # 挪超
  76,   # 俄超
  111,  # 巴西甲
  127   # 日职联
]

# 欧洲赔率公司
EUROPE_COMPANY_TABLES = [
        "will_europes", # 9     威廉希尔
        "weide_europes", # 14    韦德
        "libo_europes", # 4     立博
        "macro_europes", # 1     澳门
        "bet365_europes", # 8     BET365
        "eurobet_europes", # 18    Eurobet
        "ysb_europes", # 12    易胜博
        "interwetten_europes", # 19    Interwetten
        "snai_europes", # 7     SNAI
        "sb_europes", # 3     SB
        "jbb_europes", # 23    金宝博
        "12bet_europes", # 24    12bet
        "lj_europes", # 31    利记
        "10bet_europes", # 22    10Bet
        "ylg_europes", # 33    永利高
        "ms_europes", # 17    明陞
        "yh_europes" # 35    盈禾
]

# 亚洲赔率公司
ASIA_COMPANY_TABLES = [
        "sb_asias", # 3     SB
        "jbb_asias", # 23    金宝博
        "12bet_asias", # 24    12bet
        "lj_asias", # 31    利记
        "ylg_asias", # 33    永利高
        "macro_asias", # 1     澳门
        "bet365_asias", # 8     BET365
        "libo_asias", # 4     立博
        "weide_asias", # 14    韦德
        "ysb_asias", # 12    易胜博
        "10bet_asias", # 22    10Bet
        "ms_asias", # 17    明陞
        "yh_asias" # 35    盈禾
]

usage = "HUUUUNT-APP has actions as below :
    1   -   Match info Load
    2   -   Team  info Load
    3   -   Match info Output
    4   -   Team  info Output
    5   -   Result Update
    6   -   Europe Update
    7   -   Aisa Update
    8   -   Matches Update
    9   -   Load Result to Matches
   10   -   Calculate Scores By Matches
   11   -   Compare Scores
   12   -   Modify Results
   13   -   Modify Matches
   14   -   Modify Scores
   15   -   Modify Results,Matches,Scores
   16   -   Modify Europes Infomation
   17   -   Update match rank
   18   -   Update team rank
   19   -   Modify Asia Infomation
   20   -   Update Asia Statistics
   21   -   Update Asia Statistics For Match Year
   22   -   Daily Data Update
   23   -   Daily Stat Data Update
   24   -   Load Score Special Point
Please input action : "

def load_match_info
  match_info = MatchInfoLoad.new
  match_info.load_match_data
  match_info.close
end

def load_team_info
  team_info = TeamInfoLoad.new
  team_info.load_team_data
  team_info.close
end

def output_match_info
  match_info = MatchInfoOutput.new
  match_info.output_match_data
  match_info.close
end

def output_team_info
  team_info = TeamInfoOutput.new
  team_info.output_team_data
  team_info.close
end

def get_result_data
  result = ResultUpdate.new
  result.do_update(nil, nil)
  result.close
end

def get_europe_data
  europe = EuropeUpdate.new(EUROPE_COMPANY_TABLES)
  europe.do_update(FIX_MATCHES_TYPE1.concat(FIX_MATCHES_TYPE2), 
                   nil, nil)
  europe.close
end

def get_asia_data
  # 更新所有亚洲赔率公司数据表
  asia = AsiaUpdate.new(ASIA_COMPANY_TABLES)
  asia.do_update(FIX_MATCHES_TYPE1.concat(FIX_MATCHES_TYPE2),
                 nil, nil)
  asia.close
end

def get_matches_data
  matches = MatchesUpdate.new
  matches.do_update(1, '2010', [2])
  #matches.do_update(2, '2010', nil)
  matches.close
end

def load_result_to_matches
  r2m = Result2Matches.new
  r2m.do_update('2010-2011', [62, 69], '2010-06-30', '2011-06-30')
  #r2m.do_update('2010-2011', FIX_MATCHES_TYPE1, '2010-06-30', '2011-06-30')
  #r2m.do_update('2009', [76], '2009-01-30', '2009-12-30')
  #r2m.do_update('2010', FIX_MATCHES_TYPE2, '2010-01-30', '2010-12-30')
  r2m.close
end

def calc_scores
  score = Score.new
  score.do_update('2010-2011', [38])
  #score.do_update('2010-2011', FIX_MATCHES_TYPE1)
  #score.do_update('2010', FIX_MATCHES_TYPE2)
  score.close
end

def compare_scores
  comp_score = ScoresCompare.new
  #comp_score.do_compare('2010-2011', [38])
  comp_score.do_compare('2010-2011', FIX_MATCHES_TYPE1)
  comp_score.do_compare('2010', FIX_MATCHES_TYPE2)
  comp_score.close
end

MODIFY_TEAM_INFO = [6865,270]

def modify_results
  m_res = ResultModify.new
  m_res.do_modify(MODIFY_TEAM_INFO)
  m_res.close
end

def modify_matches
  m_match = MatchModify.new
  m_match.do_modify(MODIFY_TEAM_INFO)
  m_match.close
end

def modify_scores
  m_score = ScoreModify.new
  m_score.do_modify(MODIFY_TEAM_INFO)
  m_score.close
end

def modify_results_and_matches_and_results
  modify_results
  modify_matches
  modify_scores
end

def modify_europes
  m_europe = EuropeModify.new(EUROPE_COMPANY_TABLES)
  m_europe.do_modify()
  m_europe.close
end

def update_rank
  m_rank = RankUpdate.new
  m_rank.do_update()
  m_rank.close
end

def update_team_rank
  m_rank = RankUpdate.new
  m_rank.do_team_rank_update()
  m_rank.close
end

def modify_asias
  m_asia = AsiaModify.new(ASIA_COMPANY_TABLES)
  m_asia.do_modify()
  m_asia.close
end

def update_asia_stat
  asia_stat = AsiaStatUpdate.new
  asia_stat.delete_today_stat
  asia_stat.do_update(FIX_MATCHES_TYPE1, '2010-2011', 'ysb_asias')
  asia_stat.do_update(FIX_MATCHES_TYPE2, '2010', 'ysb_asias')
  asia_stat.close
end

def update_asia_stat_year
  asia_stat_year = AsiaStatYearUpdate.new
  asia_stat_year.do_update(FIX_MATCHES_TYPE1, '2009-2010', 'ysb_asias')
  #asia_stat_year.do_update(FIX_MATCHES_TYPE2, '2009', 'ysb_asias')
  asia_stat_year.close
end

def update_daily_data
  # start_date和end_date必须是同一天
  start_date = '2011-02-07';
  end_date = '2011-02-07';

  # 导入赛果数据
  result = ResultUpdate.new
  result.do_update(start_date, end_date)
  result.close
  
  puts "\nRESULT DATA FINISH!!!\n\n"
  
  # 导入欧洲赔率数据
  europe = EuropeUpdate.new(EUROPE_COMPANY_TABLES)
  europe.do_update(FIX_MATCHES_TYPE1.concat(FIX_MATCHES_TYPE2), 
                   start_date, end_date)
  europe.close
  
  puts "\nEUROPE DATA FINISH!!!\n\n"
  
  # 导入亚洲赔率数据
  asia = AsiaUpdate.new(ASIA_COMPANY_TABLES)
  asia.do_update(FIX_MATCHES_TYPE1.concat(FIX_MATCHES_TYPE2),
                 start_date, end_date)
  asia.close
  
  puts "\nASIA DATA FINISH!!!\n\n"
end

def update_daily_stat_data
  # end_date必须比start_date大一天
  start_date = '2011-02-07';
  end_date = '2011-02-08';
    
  # 从赛果数据中导入各联赛赛程数据表
  r2m = Result2Matches.new
  r2m.do_update('2010-2011', FIX_MATCHES_TYPE1, start_date, end_date)
  r2m.do_update('2010', FIX_MATCHES_TYPE2, start_date, end_date)
  r2m.close
  
  puts "\nRESULT2MATCH FINISH!!!\n\n"
  
  # 根据各联赛赛程数据，计算出各联赛积分榜
  score = Score.new
  score.do_update('2010-2011', FIX_MATCHES_TYPE1)
  score.do_update('2010', FIX_MATCHES_TYPE2)
  score.close
  
  puts "\nSCORE DATA FINISH!!!\n\n"
  
  # 和其他足球数据提供方比较积分榜数据
  comp_score = ScoresCompare.new
  comp_score.do_compare('2010-2011', FIX_MATCHES_TYPE1)
  comp_score.do_compare('2010', FIX_MATCHES_TYPE2)
  comp_score.close
  
  puts "\nCOMPARE FINISH!!!\n"
end

def load_score_special
  scorepoint = ScorePoint.new
  scorepoint.do_update("2010-2011")
  scorepoint.close
end

def get_actions(actions)
  actions.split()
end

def do_action(actions, usage)
  actions.each do |action|
    case action
    when "1"
      load_match_info
    when "2"
      load_team_info
    when "3"
      output_match_info
    when "4"
      output_team_info
    when "5"
      get_result_data
    when "6"
      get_europe_data
    when "7"
      get_asia_data
    when "8"
      get_matches_data
    when "9"
      load_result_to_matches
    when "10"
      calc_scores
    when "11"
      compare_scores
    when "12"
      modify_results
    when "13"
      modify_matches
    when "14"
      modify_scores
    when "15"
      modify_results_and_matches_and_results
    when "16"
      modify_europes
    when "17"
      update_rank
    when "18"
      update_team_rank
    when "19"
      modify_asias
    when "20"
      update_asia_stat
    when "21"
      update_asia_stat_year
    when "22"
      update_daily_data
    when "23"
      update_daily_stat_data
    when "24"
      load_score_special
    when "quit", "exit"
      exit
    else
      puts "Illegal command: #{action}"
      print usage
      return
    end
  end
  exit
end

print usage
while line=gets
  actions = get_actions(line)
  do_action(actions, usage)
end


