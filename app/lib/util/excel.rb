
module Huuuunt
  module Excel
    def self.included(base)
      base.extend Huuuunt::Excel
    end
    
    def get_cell_val(value)

      return value if value == nil
      
      case value
      when Float
        value = value.to_i
      when String
        value = value.strip
        #value = Iconv.iconv("UTF-8", "GBK", value.strip) if value.length > 0
      else
        $logger.info("value = #{value.class} is no Float or String")
        return nil
      end
    end
   


  end
end