require 'pathname'
require 'cgi'
require 'erb'

class WikCGI

  def initialize(wixi)
    @wixi = wixi
  end

  # handles a get request
  def get(request)
    mode, dirs, path, page, revision = parse_path(request)

    # Allow the server to do something based on request params. 
    action, actiondata, cookiemods = process_get_actions(request, path)

    # Parse cookies
    cookiehash = process_cookies(request).merge( cookiemods || {} )

    # FIXME.  
    # Correct the order of parse_path and process_post_actions to fix this.
    # This needs refreshing to fix the page being out of sync after operations have been performed.
    page = @wixi.get_page(path)

    # Load the content with the given revision
    #puts "wikCGI: get: Read: #{revision}\n"
    page.content.read(revision)
    
    # return the page as run through the template
    return 200, "text/html", render_template( File.join($s[:template_dir], $s[:default_template]), path, dirs, page, request, cookiehash, action, actiondata, mode, @wixi, revision), cookiehash
    
    # handy debug output
    # wise to remove for production really, but meh.
    rescue Exception => e
      return 500, "text/plain", $s[:error_msg] % [e.to_s, e.backtrace.join("\n")], {}
  end

# handles a get request
  def post(request)
    mode, dirs, path, page, revision = parse_path(request)

    # Allow the server to do something based on request params. 
    action, actiondata, cookiemods = process_post_actions(request, path)
    
    # Parse cookies
    cookiehash = process_cookies(request).merge( cookiemods || {} )

    # FIXME.  
    # Correct the order of parse_path and process_post_actions to fix this.
    # This needs refreshing to fix the page being out of sync after operations have been performed.
    page = @wixi.get_page(path)

    # Load the content with the given revision
    #puts "wikCGI: post: Read: #{revision}\n"
    page.content.read(revision)
    
    # return the page as run through the template
    return 200, "text/html", render_template( File.join($s[:template_dir], $s[:default_template]), path, dirs, page, request, cookiehash, action, actiondata, mode, @wixi, revision), cookiehash
    
    # handy debug output
    # wise to remove for production really, but meh.
    rescue Exception => e
      return 500, "text/plain", $s[:error_msg] % [e.to_s, e.backtrace.join("\n")], {}
  end


  private

  def process_cookies(request)
    hash = {}
    request.cookies.each{ |cookie|
      cs = cookie.to_s.split("=")
      hash[cs[0]] = cs[1]
    }

    return hash
  end

  def parse_path(request)
    # build paths
    dirs = get_dirs(request.path.to_s)
    dirs.delete_at(0) if dirs.length > 0 and dirs[0] == $s[:url_dynamic]
    path = Pathname.new( (dirs.length > 0) ? File.join(dirs) : $s[:default_page])
    page = @wixi.get_page(path)
    mode = request.query["mode"]
    revision = request.query["revision"] || nil

    return mode, dirs, path, page, revision
  end

  def delete_resource( path, resourcename )
    @wixi.storage.delete_resource( @wixi.get_page(path), resourcename )

    return "Deleted file #{resourcename}."
    rescue Exception => e
      return "Error deleting resource: #{e.to_s}."
  end

  def delete_page( path, confirm, children )
    page = @wixi.get_page( Pathname.new(path) )
    return "Wrong confirmation code." if confirm.to_s != $s[:delete_confirm]
    

    recursive = children.to_s == "yes"
    @wixi.storage.delete_page(page, recursive)

    if recursive   
      if page.children.length > 0
        return "Page, resources and children removed successfully."
      else
        return "Page and resources removed successfully, but page has no children."
      end
    end
    
    return "Page and resources successfully removed."

    rescue Exception => e
      return "Error trying to delete '#{path.to_s}': #{e.to_s}."
  end

  # return string as failure, or a hash/array of results if not.
  def search_site( term, rootpath, recursive, basename)
    page = Page.new(@wixi, Pathname.new(rootpath))
    return "Path '#{page.relpath.to_s}' does not exist, cannot search." if not page.exists

    glob = (recursive == 'yes' ? "**/*": "*")

    results = {:pages => [], :resources => []}
    Dir[File.join(page.path.to_s, glob).to_s].each{ |filename|
      relpathname = Pathname.new(filename).relative_path_from( @wixi.root )

      add = false
      if basename == "yes"
        if relpathname.basename.to_s =~ /.*#{term}.*/
          add = true
        end
      elsif relpathname.to_s =~ /.*#{term}.*/i
        add = true
      end

      # if set to return, add to the output
      if add
        if File.directory?(filename)
          results[:pages] << relpathname 
        else
          results[:resources] << relpathname
        end
      end
    }
    return "Found #{results[:pages].length} pages and #{results[:resources].length} resources.", results

    return "Crapspackle.  Term: '#{term.to_s}', root: '#{rootpath.to_s}', recursive: '#{recursive}'"
  end


  def accept_upload( resourcename, upload, path, clobber)
    return "Please provide a filename: #{resourcename}." if resourcename.length == 0

    @wixi.storage.put_resource(@wixi.get_page(path), resourcename, upload, clobber == "yes", 'wb')

    return "Upload successfully written to #{resourcename}."
    rescue Exception => e
      return "Error uploading: #{e.to_s}."
  end

  def update_page( relpath, content, newrevision)
    page = @wixi.get_page( Pathname.new(relpath) )
    puts "WikCGI: update_page: Read (no revision given)"
    page.content.read
    page.content.content = content.to_s
    return "Page successfully updated" if page.content.write(newrevision == "yes")
    return "Page failed to write!"
  end

  def set_compiler( comp )
    return nil, nil, {"compiler" => comp} if @wixi.compiler?( comp )
    return "The compiler '#{comp}' does not exist in this wiXi instance."  #if not 
  end


  # insane.
  def convert_html_to_latex( url, path )
    page = @wixi.get_page(path)
    page.ensure_exists
    content_path = page.content.filepath
    
    `#{$s[:cmd_wget_html2latex] % [content_path, url]}`
    latexversion = `#{$s[:cmd_html2latex] % content_path}`
    page.content.content = "#{$s[:default_edit_contents]}\n\n#{latexversion}"
    page.content.write

    return "Successfully converted #{url} to LaTeX."
  end

  def delete_past_revisions(path, confirm)
    page = @wixi.get_page( Pathname.new(path) )
    return "Wrong confirmation code." if confirm.to_s != $s[:delete_confirm]
   
    page.revisions.each{|rid| 
      @wixi.storage.delete_content_revision(page, rid)
    }
    return "Successfully deleted all past revisions."
  end

# ----------------- 
  # handle arguments from GET or POST
  def process_post_actions(request, path)
    args = request.query

    message, data, cookiemods = case args["action"]
      when "converthtmltolatex"
        convert_html_to_latex( args["url"], path )
      when "uploadresource"
        return accept_upload( args["filename"], args["upresource"], path, args["clobber"] )
      when "post"
        return update_page( args["page"], args["content"], args["newrevision"] )
      when "crash"
        raise "Crash ordered by user (POST)."
      when nil
        nil
      else
        "Unrecognised action '#{args['action']}' for POST requests."
    end

    return message, data, cookiemods
  end

  # handle arguments from GET or POST
  def process_get_actions(request, path)
    args = request.query

    message, data, cookiemods = case args["action"]
      when "setcompiler"
        set_compiler( args["compiler"] )
      when "search"
        search_site( CGI::unescape(args["searchterm"].to_s).to_s, CGI::unescape(args["rootpath"].to_s).to_s, args["recurse"], args["basename"])
      when "delete"
        delete_page( CGI::unescape(args["pagepath"]).to_s , args["confirm"], args["children"])
      when "deleteresource"
        delete_resource( path, CGI::unescape(args["resource"]) )
      when "deletepastrevisions"
        delete_past_revisions( CGI::unescape(args["pagepath"]).to_s, args["confirm"])
      when "crash"
        raise "Crash ordered by user (GET)."
      when nil
        nil
      else
        "Unrecognised action '#{args['action']}' for GET requests."
    end

    return message, data, cookiemods
  end


# ----------------- 

  def get_dirs(fpath)
    decoded_dirs = []
    remains = fpath
    while(remains != "/" and remains != ".")
      split = File.split(remains)
      decoded_dirs << split[1]
      remains = split[0]
      #remains = decoded_dirs[-1]
    end

    return decoded_dirs.reverse.map{|x| CGI.unescape(x) }
  end
  # Render an ERB template with some values handy for rendering.
  def render_template(template, path, dirs, page, request, cookiehash, action, actiondata, mode, wixi, revision)
    formatter = ERB.new(File.open( template, 'r' ).read())
    return formatter.result(binding).to_s
  end

end
