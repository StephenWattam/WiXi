

class PDFCompiler < Compiler

  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @pdflatex_cmd     = options[:pdflatex_cmd] || "pdflatex -interaction=batchmode -output-directory=\"%s\" \"%s\""
    @bibtex_cmd       = options[:bibtex_cmd] || "bibtex \"%s\""
    @triple_compile   = options[:triple_compile] || true
  end


  def compile
    dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc = apply_template
    outputfilename = File.join( dir, @page.title.to_s + ".pdf")

    # Remove old versions to force it to clobber
    FileUtils.rm_f(outputfilename) if File.exist?(outputfilename)


    # Write Tex into the temp directory
    File.open(texpath, 'w'){ |fout|
      fout << finaldoc
    }
    File.open(bibpath, 'w'){ |fout|
      fout << bibdoc
    }


    # copy resources from template, then overwrite with page stuff
    copy_resources( @template,  dir )
    copy_resources( @page,      dir )
  
    # construct the fun. 
    finaldoc = preamble + @page.content.content + postamble

    out, err, endcode = run_in_dir( @pdflatex_cmd % [dir, texpath], dir )
    if @triple_compile and bibdoc.length > 0 
      out, err, endcode = run_in_dir( @bibtex_cmd % bibpath, dir )
      out, err, endcode = run_in_dir( @pdflatex_cmd % [dir, texpath], dir )
      out, err, endcode = run_in_dir( @pdflatex_cmd % [dir, texpath], dir )
    end

    # outputfilename
    raise "Error: output file does not exist. \n\n Trying to find: #{outputfilename} \n\n after running: #{@pdflatex_cmd % [dir, texpath]} \n\nstdout:#{out} \n\n stderr: #{err}" if not File.exists?(outputfilename)


    FileUtils.cp( outputfilename, File.join(@page.path.to_s, @page.title.to_s + ".pdf"))
    # read result from el HTML
    return File.join( "", $s[:url_static_root], @page.relpath, @page.title.to_s + ".pdf" )
  end
end


