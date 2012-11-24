
module Huuuunt
  module DataFile
    def self.included(base)
      base.extend Huuuunt::DataFile
    end

    # 计算保存数据的文件路径
    def data_file_path(date, path, suffix)
      year,month,day = date.split('-')
      unless File.directory?(File.expand_path("#{year}/", path))
        FileUtils.mkdir(File.expand_path("#{year}/", path))
      end
      unless File.directory?(File.expand_path("#{year}/#{month.to_i}/", path))
        FileUtils.mkdir(File.expand_path("#{year}/#{month.to_i}/", path))
      end
      pathfile = File.expand_path("#{year}/#{month.to_i}/#{date}.#{suffix}", path)
      return pathfile
    end

    # 判断数据文件是否存在
    def data_file_exist?(date, path, suffix)
      year,month,day = date.split('-')
      pathfile = File.expand_path("#{year}/#{month.to_i}/#{date}.#{suffix}", path)
      return pathfile if File.exist?(pathfile)
      return false
    end

  end
end

