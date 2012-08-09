require 'time'


class CurrentDate < Macro
  DEFAULT_TIME_FORMAT = "%d/%m/%Y"

  def process(callcount, format=DEFAULT_TIME_FORMAT)
    return Time.now.strftime(format.to_s)
  end

  def self.desc
    return "Inserts the current date into the document, in \\texttt{#{Macro::escape_latex(DEFAULT_TIME_FORMAT)}} format"
  end

  def self.help
    return "Usage: CurrentDate [format string].  The format defaults to \\texttt{#{Macro::escape_latex(DEFAULT_TIME_FORMAT)}} and follows conventions as Time.strftime in the ruby apis."
  end
end
