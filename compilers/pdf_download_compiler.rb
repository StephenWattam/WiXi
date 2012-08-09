require './compilers/pdf_compiler.rb'


class PDFDownloadCompiler < PDFCompiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex, options)
    @render_container = options[:render_container] || "<a target=\"_blank\" href=\"%s\">%s</a>" 
  end

  def compile
    filename = super
    return @render_container % [filename.to_s, File.basename(filename).to_s]
  end
end



