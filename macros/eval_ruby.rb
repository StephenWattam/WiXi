
class EvalRuby < Macro
  def process(callid, code)
    Macro::escape_latex(eval(code).to_s)
  end

  def self.desc
    "Evaluates a ruby expression and returns the result, escaped, to the document.  A handy way of displaying constants."
  end

  def self.help
    "Usage: EvalRuby \"ruby string\".  Don't use return or raise statements in the ruby if you don't want everything to break."
  end
end
