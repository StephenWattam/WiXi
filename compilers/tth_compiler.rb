
class TTHCompiler < Compiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @tth_cmd     = options[:tth_cmd] || "tth -u -a -r  < \"%s\""
  end

  def compile
    # get details of compilation directory etc
    dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc = apply_template

    # Hevea outputs to stdout, so simply read its output from the pipe
    out = ""
    spawn_in_dir( @tth_cmd % texpath , dir ){ |sin, sout, serr, thr|
      #sin << finaldoc
      out += sout.read
    }

    #=~ /a href="(http:\/\/|ftp:\/\/|mailto:\/\/)/

    # FIXME: make this only rewrite relative links, and then only to images.
    if $s and $s.key?(:url_static_root)
      out.gsub!(/a href="/i, "a href=\"#{ File.join( "", $s[:url_static_root], @page.relpath, "" )}")
    end

    return out 
  end
end


