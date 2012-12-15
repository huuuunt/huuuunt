# encoding: utf-8
SplitDomain="$"
SplitRecord="~"   
SplitColumn="^"
$Lang = "cn"
$DataFullAll = 'http://www.gooooal.com/live/data/ft_all.js'
$DataChange = 'http://www.gooooal.com/live/data/ft_chg.js';
$LastTimeStamp = 0
$MatchStatus = [["","",""], ["未","未",""],["待", "待", "FT ONLY"], ["上", "上", "1st"], ["下", "下", "2nd"], 
              ["半", "半", "HT"], ["完", "完", "Fin"], ["加", "加", "Ext"], ["加1", "加1", "Ext1"], ["加2", "加2", "Ext2"],
              ["完", "完", "ExtF"], ["点", "點", "Penalty"], ["暂", "暂", "Pause"], ["斩", "斬", "Suspend"],
              ["取", "取", "Cancel"], ["改", "改", "Postp"], ["延", "延", "Later"], ["完", "完", "F1"]] 
              

def getStatus(stid) 
  ss = $MatchStatus[Integer(stid)]
  return ss ? ss[0]: ""
end

def random_str(len)
  chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
  newpass = ""
  1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
  return newpass
end
