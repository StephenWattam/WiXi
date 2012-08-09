require './compilers/pdf_compiler.rb'


class PDFEmbedCompiler < PDFCompiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex, options)
    @render_container = options[:render_container] || "<iframe id=\"pdfarea\" class=\"pdfembed\" src=\"%s\"></iframe>" 
  end

  def compile
    filename = super
    return @render_container % filename.to_s
  end
end
