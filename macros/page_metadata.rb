class PageMetadata < Macro
  def process(callcount, pagekey)
    message = @page.content.meta[pagekey]
    return "Error: key #{pagekey} does not exist." if message == nil
    return message
  end

  def self.desc
    return "Inserts the value of a given header into the document."
  end

  def self.help
    return "Usage: PageMetadata key.  Inserts the value of the key into the document, or an error if the key does not exist."

  end
end
