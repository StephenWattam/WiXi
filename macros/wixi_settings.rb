

class WixiSettings < Macro
  def process(callid, setting)
    Macro::escape_latex(($s[setting.to_sym] || "[setting #{setting} not present]").to_s)
  end

  def self.desc
    "Outputs the value of some wiki setting to the document."
  end

  def self.help
    "Usage: WixiSettings \"setting\"."
  end
end
