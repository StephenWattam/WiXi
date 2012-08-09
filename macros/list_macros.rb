class ListMacros < Macro
  def process(callcount, list = "itemize")
    str = "\\begin{#{list}}\n"
    @wixi.macros.sort.each{ |cls|
      str << "\\item \\textbf{#{cls.to_s}} --- #{eval("#{cls}::desc")} \n"
    }
    str << "\\end{#{list}}"
  end

  def self.desc
    "Lists all macros from the active WiXi object.  This list is configurable in the constants file"
  end

  def self.help
    "USAGE: ListMacros [\"listtype\"].  The list type is used as the context for the LaTeX \\item entries, so can be 'enumerate' or 'itemize' and such."
  end
end
