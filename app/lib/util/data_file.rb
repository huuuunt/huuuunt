
module Huuuunt
  module DataFile
    def self.included(base)
      base.extend Huuuunt::DataFile
    end

    def get_date_str(date)
      case date
      when String
        return date
      when Date
        return date.to_s
      else
        $logger.debug("#{date} #{date.class} is not Date or String!")
      end
    end

    # 计算保存数据的文件路径
    def data_file_path(date, path, suffix)
      date_str = get_date_str(date)
      year,month,day = date_str.split('-')
      unless File.directory?(File.expand_path("#{year}/", path))
        FileUtils.mkdir(File.expand_path("#{year}/", path))
      end
      unless File.directory?(File.expand_path("#{year}/#{month.to_i}/", path))
        FileUtils.mkdir(File.expand_path("#{year}/#{month.to_i}/", path))
      end
      pathfile = File.expand_path("#{year}/#{month.to_i}/#{date_str}.#{suffix}", path)
      return pathfile
    end

    # 判断数据文件是否存在
    def data_file_exist?(date, path, suffix)
      date_str = get_date_str(date)
      year,month,day = date_str.split('-')
      pathfile = File.expand_path("#{year}/#{month.to_i}/#{date_str}.#{suffix}", path)
      if File.exist?(pathfile)
        $logger.debug("#{pathfile} exist!!!")
        return pathfile
      end
      return false
    end

  end
end

