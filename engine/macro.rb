class Macro
  def initialize(wixi, page)
    @wixi = wixi
    @page = page
  end

  def process(call_count)
    return "MACRO STUB: Number of times called: #{call_count}."
  end

  def self.desc
    return "MACRO STUB: A brief description of the macro.  Override this method when writing your own."
  end

  def self.help
    return "MACRO STUB: A quick usage string describing the options and command line.  Override this method when writing your own."
  end

  private

  def self.escape_latex(str)
    str.gsub(/[%{$\]\\\[}]/) {|m| "\\" + m[0] }
  end
end
