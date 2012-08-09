require 'pathname'
require 'fileutils'

# Handles access to resources
#  Normally this will be some kind of disk access
class StorageManager
  def initialize
  end

  def put_content(page, content, keep_old_revision=true)
    # Read the page, then write it in a new filename
    if keep_old_revision
      current = (list_revisions(page).max || 0)+ 1  # Increment the revision count on the old page
      cur_page = Page.new(page.wixi, page.relpath)
      cur_page.content.read
      
      # Write to the revision copy.
      File.open(content_fullpath(page, current), 'w'){|fout|
        fout << cur_page.content.content(false)# load the page and read its data, do not apply macros
      }
    end

    # Then write the new content to the normal filename.
    File.open(content_fullpath(page), 'w'){ |fout|
      fout << content
    }
  end

  # Gets the content of a page, raw.
  # Returns blank if the page is not there
  def get_content(page, revision)
    File.open(content_fullpath(page, revision), 'r').read || ""
  end

  # Gets the directory path of a page (without the filename).
  def page_dirpath(page)
    page.path
  end

  # Returns the basename of the CONTENT, i.e. "Home.wtex" for /Home,
  # "Test.wtex" for /This/Is/A/Test
  def content_basename(page, revision=nil)
    rev = (revision ? ".#{revision}" : "")
    return page.basename.to_s + "." + page.wixi.options[:ext] + rev
  end

  # Returns the full path of the page, including the basename.
  def content_fullpath(page, revision=nil)
    File.join(page_dirpath(page), content_basename(page, revision))
  end

  def content_exists?(page, revision=nil)
    File.exists?(content_fullpath(page, revision))
  end

  def trycreate_page(page)
    FileUtils.mkdir_p(page.wixi.root + page.relpath)
  end



  def list_revisions(page)
    dirname = page.path
    revision_regex = %r{#{page.wixi.options[:ext]}\.(?<revision>[0-9]+$)}
    revisions = []


    Dir.glob(File.join(dirname.to_s, content_basename(page) + "\.*")).each{|fn|
      matches = revision_regex.match(fn.to_s)
      revisions << matches[:revision].to_i
    }
    return revisions 
  end

  def delete_page(page, recursive)
    dirname = page.path
    raise "Cannot delete page that does not exist: '#{page.relpath.to_s}'." if not page_exists?(page)

    # Handle recursion if the children are present
    if page.children.length > 0 and recursive 
      FileUtils.rm_rf( [dirname] )
    else
      FileUtils.rm_f( Dir.glob(File.join( dirname.to_s, "*" )) )
      FileUtils.rmdir( dirname.to_s )
    end
  end

  def delete_content_revision(page, revision)
    FileUtils.rm_f(content_fullpath(page, revision))
  end

  # Output a file as a resource for a given page.
  # If clobber is set, this will overwrite a resource with the same name.
  def put_resource(page, resourcename, content, clobber=false, mode='wb')
    filepath = page.path + resourcename 

    raise "File already exists!" if File.exists?(filepath) and not clobber 

    File.open(filepath, 'wb'){ |fout|
      fout << content
    }
  end

  # Remove a resource from a page, deleting it forevermore!!!!!
  def delete_resource(page, resourcename)
    filename = page.path + resourcename
    FileUtils.rm(filename)
  end


  # Does a page already exist at the given place?
  def page_exists?(page)
    path = page.wixi.root + page.relpath
    raise "File already exists, but is not a directory: cannot create page path '#{path.to_s}'." if File.exist?(path) and not File.directory?(path)
    File.exists?(path)
  end

  # Returns a list of child pages for a given path and wixi.
  def child_pages(wixi, relpath)
    root    = wixi.root
    path    = root + relpath
    clist   = []
    exclude = [".", ".."]
    
    # return blank if the path does not exist
    return clist if not File.exists?(path)

    # list the child directories.
    Dir.foreach(root + relpath){|fp| 
      clist << fp if File.directory?(File.join(root+relpath, fp)) and not exclude.include?(fp) and not fp =~ /\..*/
    }

    
    return clist
  end

  # Return a list of page resources
  def page_resources(wixi, relpath, content_filename)
    root    = wixi.root
    path    = root + relpath
    list    = []
    exclude = [".", "..", "#{content_filename}"]

    # Return an empty list if the dir does not exist.
    return list if not File.exists?(path)

    # List all files but the content filename
    Dir.foreach(path){ |fp| 
      list << fp if not File.directory?(File.join(path, fp)) and not exclude.include?(fp)# and not fp =~ /#{content_basename(page)}\.#{page.wixi.options[:ext]}\.[0-9]+$/
    }
    return list
    
  end
end
