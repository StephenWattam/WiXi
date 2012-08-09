require 'shellwords'
require 'yaml'

class Content
  attr_reader :page, :exists, :sync, :rendersync, :filename, :meta, :filepath, :htmlcontent, :template, :is_template, :bibtex, :is_bibtex

  def initialize(page)
    @page       = page
    @dirpath    = page.wixi.storage.page_dirpath(page)
    @filename   = page.wixi.storage.content_basename(page) 
    @filepath   = page.wixi.storage.content_fullpath(page)
  
    # spare vals for later
    @content     = ""
    @htmlcontent = ""
    @exists      = page.wixi.storage.content_exists?(page)
    @sync        = true
    @rendersync  = false 
    @template    = nil
    @bibtex      = nil
    @is_template = false
    @is_bibtex   = false
    @meta        = {}

    if @page.wixi.options[:sanitise_utf8]
      require 'iconv'
      @sanitse_ic = Iconv.new('UTF-8//IGNORE', 'UTF-8') 
    end
  end

  # Retrieves content, applying macros as it does
  def content(macro = true)
    return apply_macros(@content) if macro
    return @content
  end

  # TODO: set which compiler works
  def render(compiler)
    # if this renderer is synced, then there is no need for a compile cycle.
    return if @rendersync

    #read if not @sync
    #@template.read if @template and not @template.content.sync
    #@bibtex.read if @bibtex and not @bibtex.content.sync

    #remove first line if it's a template
    if not @is_template and not @is_bibtex
      @template.content.read
      @bibtex.content.read if @bibtex
      # compile using the current compiler in the wixi
      intermediate = @page.wixi.compile(@page, @template, @bibtex, compiler)
    else
      # Templates merely dump their code as text
      intermediate = apply_macros(@content.dup.to_s)
    end 

    # compile.
    @htmlcontent = intermediate
    @rendersync  = true
  end

  # returns preamble, postamble from a template, 
  # splitting by TEMPLATE_CONTENT_PLACEHOLDER
  def get_template_ambles
    return "", "" if not @is_template
    ambles = (content(true)).split(@page.wixi.options[:template_content_placeholder]) ## applies macros, then splits.
    return ambles[0].to_s, ambles[1].to_s
  end

# ====== Editing
  # Loads a template from a relative path.
  def load_template(path)
    @template = @page.wixi.get_page(Pathname.new(path.strip) )
  end
  
  # Loads a bibtex file from a relative path.
  def load_bibtex(path)
    @bibtex = @page.wixi.get_page(Pathname.new(path.strip) )
  end

  # Loads the YAML at the top of the page into the metadata
  # hash which is then used for misc. things such as template specification
  def process_metadata
    if m = @content.match(/^#{@page.wixi.options[:end_preamble]}/)
      # prune any leading whitespace and % signs
      preamble = @content[0..m.begin(0)-1].gsub(/^\s*%*\s*/, "").strip if m.begin(0) > 0
      #puts "\n\n\nPreamble: '#{preamble}'\n\n\n"
    else
      #puts "\n\n\nNOT CONTENT (is a template)\n\n\n"
      @is_template = true
      return
    end

    
    # At this point, we have fields to read.
    @meta = YAML.load(preamble)
    #puts "\n\n\n: class => #{@meta.class.to_s}\n\n"
    @meta = {} if not @meta.class == Hash

    # check if the template key exists
    @is_template = (@meta['template'] == nil) && (@meta['topic'] == nil)
    # See if this is or has a bibtex file associated with it.
    @is_bibtex   = (@meta['topic'] != nil)

    # load appropriate things from disk
    load_bibtex(@meta['bibtex'])      if not @is_bibtex and @meta['bibtex'] != nil
    load_template(@meta['template'])  if not @is_template and not @is_bibtex


    # return
    return

    rescue Exception => e
      @meta = {}
      @is_template = true
      return 
  end

  # Accept new content
  #
  # This updates metadata and optionally tidies the input
  # to remove invalid UTF8 characters.
  def content=(str)
    @sync       = false
    @content    = clean_input(str)
    @rendersync = false
    process_metadata
  end

  # Applies macros to the macro sections of a document
  # Should be called by the page when rendering, but only once.
  #
  # Macros are re-entrant, but retain an instance to allow counting and the like.
  def apply_macros(str)
    # for all matches of /MACRO_START([A-Za-z0-9 \-_\/\\"']+)MACRO_END/ 
    macro_instances = {}
    counts = Hash.new(-1)

    str.gsub(/#{@page.wixi.options[:macro_start]}([A-Za-z0-9 \[\]\-:;_%$\/\\"']+)#{@page.wixi.options[:macro_end]}/){|mdata|
      command = Shellwords.shellwords($1.to_s)
      
      # Find the command
      yield $1 if command.length == 0
      raise "ERROR: Macro #{command[0].to_s} does not exist." if not @page.wixi.macros.include?(command[0])
      
      cmd   = command[0]
      args  = command[1..-1]


      # Get an instance from the wixi,
      # but reuse one if it has been instantiated for this page
      if macro_instances[cmd]
        inst = macro_instances[cmd]
      else
        inst = macro_instances[cmd] = @page.wixi.macro_instance(cmd, @page) if not macro_instances[cmd] 
      end

      # Run the macro by expanding the arguments.
      # Keep track of the amount it's been run using the counts hash.
      inst.process(counts[cmd] += 1, *args)
    }
  end

# ====== IO
  # Read from disk, optionally clean invalid UTF8
  def read(revision=nil)
    @exists     = @page.wixi.storage.content_exists?(@page, revision) 
    @content    = @exists ? clean_input(@page.wixi.storage.get_content(@page, revision)) : ""
    @sync       = true
    @rendersync = false
    process_metadata
  end

  # Write to disk
  def write(create_revision=true)
    #puts "\n\n Writing #{@page.basename} to disk\n\n"
    # Nothing to do if in sync
    return false if @sync
    
    # Make sure we have a dir to write into
    @page.ensure_exists

    # put content into storage
    @page.wixi.storage.put_content(@page, @content, create_revision)
    
    # We have just synced.
    @sync = true
  end

  private

  # Ensure input conforms to UTF8 specifications.
  def clean_input(str)
    return @sanitse_ic.iconv(str + ' ') if @page.wixi.options[:sanitise_utf8]
    return str.to_s
  end

end
