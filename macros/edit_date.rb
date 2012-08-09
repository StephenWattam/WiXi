require 'time'


class EditDate < Macro
  DEFAULT_TIME_FORMAT = "%d/%m/%Y"

  def process(callcount, format=DEFAULT_TIME_FORMAT)
    t = File.mtime(@page.content.filepath)
    return t.strftime(format.to_s)
    rescue
      return Time.now.strftime(format.to_s)
  end

  def self.desc
    return "Inserts the date of the last edit to a page's content, in \\texttt{#{Macro::escape_latex(DEFAULT_TIME_FORMAT)}} format"
  end

  def self.help
    return "Usage: EditDate [format string].  The format defaults to \\texttt{#{Macro::escape_latex(DEFAULT_TIME_FORMAT)}} and follows conventions as Time.strftime in the ruby apis."
  end
end

