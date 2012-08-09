

class DeTeXCompiler < Compiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @detex_cmd        = options[:cmd_detex] || "detex \"%s\""
    @render_container = options[:render_container] || "%s" 
  end


  def compile
    # get details of compilation directory etc
    dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc = apply_template

    # Hevea outputs to stdout, so simply read its output from the pipe
    out = ""
    spawn_in_dir( @detex_cmd % texpath, dir ){ |sin, sout, serr, thr|
      #sin << finaldoc
      out += sout.read
    }

    return @render_container % out
  end
end


