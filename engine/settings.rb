# Manages a hash - derived settings object.
# This settings object may be set to be thread-safe.

require 'yaml'
require 'thread'

# A thread safe hash-like class with the ability to save and load settings to/from YAML.
class SettingsManager < Hash
  attr_accessor :filename

  def initialize(defaults={}, initial_value=nil, filename=nil, loadfile=false)
    super(initial_value)
    @mutex = Mutex.new
    @filename = filename


    @defaults = defaults || {}
    reset_to_defaults

    # Load file over the defaults if the user wishes to.
    if File.exist?(filename) and loadfile
      load(false)
    end
  end

  # Reset to the defaults.
  def reset_to_defaults
    @mutex.synchronize{
      @defaults.each{|k,v|
        self[k] = v
      }
    }
  end


  # save to a file other than the filename
  def save_as(path, overwrite=true)
    write_file(overwrite, path)
  end

  # save to the internal filename deely.
  def save(overwrite=true)
    write_file(overwrite, @filename)
  end

  # internal save method
  def write_file(overwrite=false, path=nil)
    @mutex.synchronize{
      # get the filepath internally, prefer argument
      filepath = path or @filename
      raise "No filepath given to save settings." if not filepath

      # check overwrite status
      raise "A file exists already at #{filepath}.  Use overwrite=true to clobber" if File.exist?(filepath) and not overwrite

      # write the file
      File.open( filepath, 'w' ) do |out|
        dump = Hash.new()
        keys.each{ |k| dump[k] = self[k] }

        YAML.dump( dump, out )
      end

      # update thingy
      @filename = filepath
    }
  end

  def load(clear=false, filename = @filename)
    @mutex.synchronize{
      @filename = filename

      hash = YAML.load_file( filename )
      self.clear if clear
      self.merge!(hash)
    }
  end
end

# Prevents some keys from being unsatisfied.  Throws an error when the keys are not loaded in the constructor
# either by loading a file or by setting default values for said keys.
class RestrictiveSettings < SettingsManager
  def initialize(mandatory_keys=[], defaults={}, initial_value=nil, filename=nil, loadfile=false)
    super(defaults, initial_value, filename, loadfile)
    
    # Store a list of keys that must be present
    @mandatory_keys = mandatory_keys or []
    check, k = check_keys
    raise "Mandatory setting '#{k}' not preset in defaults or settings file." if not check
  end

  private
  def check_keys
    @mutex.synchronize{
      @mandatory_keys.each{|k|
        return false, k if not self.key?(k)
      }
    }
    return true, ""
  end
end

## test script
#x = SettingsManager.new({}, nil, 'test')
#x[4] = "test"
#x[5] = "test"
#x[6] = "test"
#x.save



#y = SettingsManager.new(nil,nil, "test", true )
##y.save
#y.save_as( "test2" )
