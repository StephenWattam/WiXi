


class Fortune < Macro
  def process(callid)
    Macro::escape_latex((`fortune`).to_s)
  end

  def self.desc
    "Returns a random fortune from the unix command with the same name.  Requires that 'fortune' is in your $PATH."
  end

  def self.help
    "Usage: Fortune"
  end
end
