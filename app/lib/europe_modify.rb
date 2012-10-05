class EuropeModify

  @@europe_company = []

  def initialize(company_tables)
    @mysql = MysqlAccess.new()
    @util = HuuuuntUtil.new()
    @@europe_company = company_tables
  end

  def close
    @mysql.close
  end

  def do_modify()
    @@europe_company.each do |company|
      #puts company
      #@mysql.add_columns_to_europe_tables(company)
      #@mysql.add_index_matchinfono_to_tables(company)
    end
    @mysql.commit
  end
end