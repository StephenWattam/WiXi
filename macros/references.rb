

class References < Macro
  def process(callcount)
    return "\\bibliography{#{@page.basename}}{}"
  end

  def self.desc
    return "Inserts a references section, using the bibtex file specified in the header."
  end

  def self.help
    return "Usage: References."
  end
end
