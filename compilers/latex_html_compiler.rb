#@latex2html_cmd = "latex2html -split 0 -noaddress -noinfo -nonavigation -nosubdir \"%s\""

#
#
#  
# Note: LATEX2HTML DOES NOT HANDLE SPACES IN FILENAMES
class LaTeX2HTMLCompiler < Compiler
  def initialize(page, template, bibtex=nil, options={})
    super(page, template, bibtex)
    @latex2html_cmd   = options[:cmd_latex2html] || "latex2html -split 0 -noaddress -noinfo -nonavigation -nosubdir \"%s\""
    @copy_images      = options[:copy_images] || false
  end

  def compile
    dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc = apply_template
    outfilename = File.join( dir, @page.title.to_s + ".html")

    # Remove output file if one exists, to force updates
    FileUtils.rm_f(outfilename) if File.exist?(outfilename)

    # needs writing to a file
    File.open(texpath, 'w'){ |fout|
      fout << finaldoc
    }


    # copy resources from template, then overwrite with page stuff
    copy_resources( @template,  dir)
    copy_resources( @page,      dir )
  
    # construct the fun. 
    finaldoc = preamble + @page.content.content + postamble

    # Run the command to convert stuff
    out, err, endcode = run_in_dir( @latex2html_cmd % texpath, dir )



    raise "ERROR: no output file.\n\nNote that LATEX2HTML DOES NOT support spaces in filenames.\n\ncmd='#{@latex2html_cmd % texpath}'\n\nstderr='#{err}'." if not File.exist?(outfilename)

    # read result from el HTML
    result = File.open( outfilename, 'r').read

    result.gsub!(/^.*<BODY >/m, "")
    result.gsub!(/<HR>\s+<\/BODY>.*$/m, "")

    # FIXME: make this more durable
    if $s and $s.key?(:url_static_root)
      result.gsub!(/SRC="/i, "SRC=\"#{ File.join( "", $s[:url_static_root].to_s, @page.relpath, "" )}")
    end

    if @copy_images 
      # This copies all generated images, but the images are not generated correctly.
      ## copy all generated images back into the dir.
      Dir.glob( File.join( dir, "img*.png")).each{ |img|
        FileUtils.cp( img, @page.path.to_s )  if img =~ /.*\/img[0-9]+.png/
      }
    end


    return result 
  end

end

