class AsiaModify

  @@asia_company = []

  def initialize(company_tables)
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
    @@asia_company = company_tables
  end

  def close
    @mysql.close
  end

  def do_modify()
    @@asia_company.each do |company|
      #puts company
      #@mysql.add_index_matchinfono_to_tables(company)
    end
    @mysql.commit
  end
end