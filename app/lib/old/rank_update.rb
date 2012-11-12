require 'rubygems'
require 'open-uri'
require 'net/http'
require 'iconv'
require 'date'
require 'fileutils'

class RankUpdate

  def initialize
    @mysql = MysqlAccess.new()
  end

  def close
    @mysql.close
  end

  def do_update
    @mysql.truncate_rank_changes()
    @mysql.insert_rank_changes()
  end

  def do_team_rank_update
    @mysql.update_rank_changes()
  end
end