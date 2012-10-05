
require 'win32ole'
require 'iconv'

class ExcelAccess
  def initialize
    @excel = WIN32OLE::new('excel.Application')
  end

  def open_file(file_path)
    @workbook = @excel.Workbooks.Open(file_path)
    @worksheet = @workbook.Worksheets(1)
    @worksheet.Select
  end

  def new_file(file_path)
    @excel.visible = false
    @workbook = @excel.workbooks.add
    @worksheet = @workbook.Worksheets(1)
    @workbook.saveas(file_path)
  end

  def get_value(row, col)
    @worksheet.Range("#{col}#{row}").Value
  end

  def get_row_value(row, col_start, col_end)
    @worksheet.Range("#{col_start}#{row}:#{col_end}#{row}").Value
  end

  def set_value(row, col, value)
    @worksheet.Range("#{col}#{row}").Value = value
  end

  # 该函数无法正常使用
  def set_row_value(row, col_start, col_end, value_arr)
    @worksheet.Range("#{col_start}#{row}:#{col_end}#{row}").Value = value_arr
  end

  def close
    @workbook.Close
    @excel.Quit
  end
end
