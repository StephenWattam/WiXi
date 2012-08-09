

class PlainTextCompiler < Compiler

  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @render_container = options[:render_container] || "<div style=\"font-family: monospace; white-space: pre-wrap;\">%s</div>"
  end

  def compile
    preamble, postamble = @template.content.get_template_ambles
    return @render_container% "#{preamble}#{@page.content.content}#{postamble}"
  end
end


