require 'tmpdir'
require 'fileutils'
require 'open3'

class Compiler
  def initialize(page, template, bibtex=nil, options={})
    # The options can be thrown away, since there are none for this compiler.

    # Store for later use
    @page       = page
    @template   = template
    @bibtex     = bibtex

    # Ensure both page and template are up to date.
#    @template.content.read
#    @page.content.read ## Allow old versions to compile
#    @bibtex.content.read if @bibtex
  end

  # Stub.
  # Return some HTML content for the page
  def compile
    return ""
  end

  # Copy resources from the page to the temp directory
  def copy_resources( page, dir )
    page.resources.each{ |file|
      FileUtils.cp( page.path + file, File.join(dir, file) )
    }
  end

  # Apply a template to some content.
  # This copies a template "under" of content and merges the two directories
  # so that resources are shared between the two
  #
  # Also applies bibtex files by copying them into a .bib file, if relevant
  #
  def apply_template
    dir = File.join( Dir.tmpdir, @page.wixi.options[:build_dir_prefix], @page.relpath  );
    FileUtils.mkdir_p( dir ) if not File.exists?( dir )
   
    # The latex file to use for this compilation 
    texpath = File.join( dir, @page.title.to_s + ".tex" )
    bibpath = File.join( dir, @page.title.to_s + ".bib" )

    # Write Tex into the temp directory
    preamble, postamble = @template.content.get_template_ambles
  
    # construct the fun. 
    finaldoc = preamble + @page.content.content + postamble
    bibdoc   = @bibtex ? @bibtex.content.content : ""

    # Return everything under the sun
    return [dir, texpath, preamble, postamble, finaldoc, bibpath, bibdoc]
  end

  # very similar to Open3.popen3
  def spawn_in_dir( cmd, dir, pw=IO::pipe, pr=IO::pipe, pe=IO::pipe )
    pid = spawn(*cmd, :chdir => dir, STDIN=>pw[0], STDOUT=>pr[1], STDERR=>pe[1])
    wait_thr = Process.detach(pid)  

    # close various bits of pipes.
    pw[0].close
    pr[1].close
    pe[1].close

    # sync writes
    pw[1].sync = true
    pi = [pw[1], pr[0], pe[0], wait_thr]

    if defined? yield
      begin
        return yield(*pi)
      ensure
        [pw[1], pr[0], pe[0]].each{|p| p.close unless p.closed?}
        wait_thr.join
      end
    end

    # Return stdin, stdout, stderr for the process
    return pi
  end

  # Run a command in a directory
  # Handles all the nastiness required to manage popen3,
  # and waits for the thread to end before returning (blocks)
  def run_in_dir( cmd, dir )
    outstr = ""
    errstr = ""
    endcode = 0

    sin, sout, serr, thr = spawn_in_dir( cmd, dir )
    outstr = sout.read
    errstr = serr.read

    # close handles
    sin.close
    sout.close
    serr.close

    # wait to end
    endcode = thr.value

    return [outstr, errstr, endcode]
  end
end

