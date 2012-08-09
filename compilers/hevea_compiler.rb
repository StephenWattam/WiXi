
class HeveaCompiler < Compiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @hevea_cmd        = options[:cmd_hevea] || "hevea -s"
  end

  def compile
    # get details of compilation directory etc
    dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc = apply_template

    # Hevea outputs to stdout, so simply read its output from the pipe
    out = ""
    spawn_in_dir( @hevea_cmd , dir ){ |sin, sout, serr, thr|
      sin << finaldoc
      out += sout.read
    }

    # Strip the HTML tags and other crap to get only the content
    out.gsub!(/^.*<!--HEVEA command line is: #{@hevea_cmd} -->/m, "")
    out.gsub!(/<!--ENDHTML-->.*$/m, "")

    return out 
  end
end

