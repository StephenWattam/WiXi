require './engine/content.rb'
require 'fileutils'

# This class represents both existent and non-existent pages in the wiki.
# A page is created from a path and a WiXi object that contains the root.  
# It is, on disk, a folder containing all of its own resources plus the content file,
# which is an object accessible through the .content method.
#
# Pages have titles and paths from the root, but they do not define anything other than position in the wiki.
#  all else is accomplished through reading content data into the Content object.
class Page
  attr_reader :basename, :wixi, :path, :exists, :content, :title, :relpath, :revisions

  # Create a new page object.
  # Pages must be created from a wixi object (containing a root path)
  #  and an associated relative path from the root of this wixi container.
  def initialize(wixi, relpath)
    @wixi       = wixi
    @relpath    = relpath
    @path       = @wixi.root + relpath
    @basename   = relpath.basename
    @title      = @basename
    @content    = Content.new(self)
    @revisions  = @wixi.storage.list_revisions(self)
    @exists     = @wixi.storage.page_exists?(self)
  end

  # Is this page a template page?
  # This is entirely defined at the moment by the content object.
  def is_template
    @content.is_template
  end

  def special?
    @content.is_template or @content.is_bibtex
  end

  # Return a list of files associated with the page.
  # This is, practically, all files in the page directory, minus the page content itself.
  def resources 
    @wixi.resources(@relpath, @content.filename)
  end

  # Creates the page dir if it does not exist already
  # also creates any intermediate directories.
  def ensure_exists
    @wixi.storage.trycreate_page(self)
  end

  # Dekete the page
  #  If recursive, also delete pages lower down
  def delete(recursive=false)
    @wixi.storage.delete_page(self, recursive)
  end

  # Get a list of child pages from this page
  # This is a simple convenience function call to the parent WiXi object
  def children
    @wixi.children(@relpath)
  end
end
