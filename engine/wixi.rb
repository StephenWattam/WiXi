require 'pathname'
require './engine/page.rb'
require "./engine/storage_manager.rb"
require "./engine/compiler.rb"
require "./engine/macro.rb"
require './engine/settings.rb'

class WiXi
  attr_reader :root, :storage, :macros, :options
  OPTION_DEFAULTS = {:macro_start   => "%macro{{{",       # The bracketing around macro calls
                     :macro_end     => "}}}",
                     :end_preamble  => "%----",           # The line which signals the end of a preamble
                     :template_content_placeholder => "%content%", # The place where content is injected in a template
                     :sanitise_utf8 => true,
                     :ext           => "wtex",
                     :build_dir_prefix => "wixicompile"
                    }

  def initialize(root, allcompilers, compilerdir, macros, macrodir, options={})
    @root     = Pathname.new(root)
    @storage  = StorageManager.new

    # Load options
    @options  = OPTION_DEFAULTS.merge(options)

    # Load the macros
    load_macro_classes(macros, Pathname.new(macrodir))

    # Load the list of compilers into the system.
    load_compiler_classes(allcompilers, Pathname.new(compilerdir))
  end

  # compile using the internal compiler
  def compile(page, template, bibtex, compilerkey=@compilers.keys[0])
    opts = @compilers[compilerkey][:options] || {}
    comp = eval("#{@compilers[compilerkey][:class]}.new(page, template, bibtex, opts)")
    return comp.compile
  end

  def compilers
    return @compilers.keys
  end

  def compiler?(compilerkey)
    return @compilers.keys.include?(compilerkey)
  end

  def get_page(relpath)
    p = Page.new(self, relpath)
  end

  def page_exists?(relpath)
    get_page(relpath).exists
  end
    
  def resources(relpath, content_filename = "")
    @storage.page_resources(self, relpath, content_filename)
  end

  def children(relpath)
    @storage.child_pages(self, relpath)
  end

  def macro_instance(macroname, page)
    return eval("#{macroname}.new(self, page)")
  end

  private
  def load_compiler_classes(compilers, compiler_dir)
    new_compilers = {} #Don't update until we are sure we have compilers in the list.

    # Load the files.
    compilers.each{ |name, info|
      begin
        new_compilers[name] = {:class => info[:class], :options => info[:options]} if load(compiler_dir + info[:file])
      rescue Exception => e
        raise "Error loading compiler #{name} from file #{compiler_dir + info[:file]}. :\n #{e.to_s} \n\n#{e.message.to_s}"
      end
    }
   
    # If some loaded, then add to the list, else do not commit changes and throw an exception
    raise "Content compilers must be provided" if new_compilers.length < 1
    @compilers = new_compilers
  end

  
  # Load macros from the macro dir, so that later they can
  # be addressed by class name
  def load_macro_classes(macros, macro_dir)
    @macros = []

    macros.each{ |cl, fname|
      begin
        @macros << cl if load (macro_dir + fname)
      rescue Exception => e
        raise "Error loading macro #{cl} from file #{macro_dir + fname}. :\n #{e.to_s} \n\n#{e.message.to_s}"
      end
    }
  end
end
