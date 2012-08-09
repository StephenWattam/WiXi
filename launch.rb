#!/usr/bin/env ruby

#################################################################################################################
#                                  Default settings and mandatory keys
#################################################################################################################
# Settings 
mandatory = [:port, :bind_address,      # Server config 
             :ht_resource_path,         # Where to find the ht resources like css
             :url_static_root, :url_resources, :url_dynamic, # Where to address the three kinds of access
             :delete_confirm,           # What to type to confirm deletion
             :use_ink_syntax_highlighting, # Use ink when viewing templates? 
             :app_title,                # The title shown in the menu
             :error_msg,                # The error message for low level HTTP errors
             :default_edit_contents,    # What to put in the textarea if no content exists yet.,
             :base_search_dir,          # Where to search using grep functionality
             :template_dir,             # The directory to find templates in
             :default_template,         # The default template to render using
             :sub_templates,            # A list of sub templates for a set of keys, edit, display, compile, delete, upload, search.
             :default_page,             # Where to go if no url is specified.
             :default_compiler,         # The key of the compiler to use if none is selected.
########################################################## Affect WiXi Engine from here down
             :macro_dir,                # Directory where macros may be found
             :compiler_dir,             # Directory where compilers may be found
             :macros,                   # A list of macros with their names
             :compilers,                # A list of compilers, with names
             # From wixi.rb
             :macro_start, :macro_end, :end_preamble, :template_content_placeholder, :sanitise_utf8, :ext, :build_dir_prefix
             ]
             
defaults = {:port                       => 8080,
            :bind_address               => nil,
            :ht_resource_path           => "htresources",
            :url_static_root            => "static",
            :url_resources              => "resources",
            :url_dynamic                => "",
            :delete_confirm             => 'ConfirmDelete',
            :use_ink_syntax_highlighting => false,
            :app_title                  => "Wi&chi;i",
            :error_msg                  => "Error: %s:\n\n%s",
            :base_search_dir            => "",
            :default_edit_contents      => "%template: Templates/Article
%----

\\author{}
\\title{}
\\maketitle


%macro{{{References}}}
",
            :template_dir               => "./resources/template/",
            :default_template           => "default.erb",
            :sub_templates              => {"edit"     => "edit.erb",
                                            "display"  => "display.erb",
                                            "compile"  => "compile.erb",
                                            "delete"   => "delete.erb",
                                            "upload"   => "upload.erb",
                                            "config"   => "config.erb",
                                            "search"   => "search.erb"},
            :default_page               => "Home",
            :default_compiler           => "LaTeX2HTML",
            :cmd_html2latex             => "gnuhtml2latex -s %s",
            :cmd_wget_html2latex        => "wget -q -k -O %s %s",
########################################################## Affect WiXi Engine from here down
            :macro_dir                  => "macros",
            :compiler_dir               => "compilers",
            :compilers                  => 
            {   "Download"   => {:class   => "PDFDownloadCompiler",  :file => "pdf_download_compiler.rb",
                                 :options => {:pdflatex_cmd => "pdflatex -interaction=batchmode -output-directory=\"%s\" \"%s\"",
                                              :bibtex_cmd => "bibtex \"%s\"",
                                              :triple_compile => true,
                                              :render_container => "<h3>Download</h3><p>Download <a target=\"_blank\" href=\"%s\">%s</a></p>"}},
                "Embed"      => {:class => "PDFEmbedCompiler",     :file => "pdf_embed_compiler.rb",
                                 :options => {:pdflatex_cmd => "pdflatex -interaction=batchmode -output-directory=\"%s\" \"%s\"",
                                              :bibtex_cmd => "bibtex \"%s\"",
                                              :triple_compile => true,
                                              :render_container => "

<script type=\"text/javascript\"> 
function resizeFrame(){ 
    newheight=Math.max(window.innerHeight - 150, 100);
    document.getElementById('pdfarea').style.height = newheight + \"px\"; 
}

window.onresize=resizeFrame;
window.onload=resizeFrame;
</script> 

<iframe onclick=\"resizeFrame\" id=\"pdfarea\" class=\"pdfembed\" src=\"%s\"></iframe>"}},
               "Plain"      => {:class => "PlainTextCompiler",    :file => "plain_text_compiler.rb",
                                 :options => {:render_container => "<div style=\"font-family: monospace; white-space: pre-wrap;\">%s</div>"}},
               "Hevea"      => {:class => "HeveaCompiler",        :file => "hevea_compiler.rb",
                                 :options => {:cmd_hevea => "hevea -s"}},
                "LaTeX2HTML" => {:class => "LaTeX2HTMLCompiler",   :file => "latex_html_compiler.rb",
                                 :options => {:copy_images    => true, 
                                              :cmd_latex2html => "latex2html -split 0 -noaddress -noinfo -nonavigation -nosubdir \"%s\""}},
               "DeTeX"      => {:class => "DeTeXCompiler",        :file => "detex_compiler.rb",
                                 :options => {:cmd_detex        => "detex \"%s\"",
                                              :render_container => "<div style=\"font-family: monospace; white-space: pre-wrap;\">%s</div>"}},

               #"PlasTeX"    => {:class => "PlasTexCompiler",      :file => "plastex_compiler.rb",
                                 #:options => {}},
                "TtH"        => {:class => "TTHCompiler",          :file => "tth_compiler.rb",
                                 :options => {:tth_cmd => "tth -u -a -r  < \"%s\""}}
            },
            :macros                     => {"CurrentDate"   => "current_date.rb",
                                            "EvalRuby"      => "eval_ruby.rb",
                                            "EditDate"      => "edit_date.rb",
                                            "PageMetadata"  => "page_metadata.rb",
                                            "References"    => "references.rb",
                                            "ListMacros"    => "list_macros.rb"},
            # from wixi.rb, OPTION_DEFAULTS
            :macro_start                => "%macro{{{",       
            :macro_end                  => "}}}",
            :end_preamble               => "%----",           
            :template_content_placeholder => "%content%", 
            :sanitise_utf8              => true,
            :ext                        => "wtex",
            :build_dir_prefix           => "wixicompile"
                    
}




#################################################################################################################
#################################################################################################################
#################################################################################################################



#Check arguments are sufficient
if ARGV.length == 0
  $stderr.puts "Please provide a path where the content is/may be stored, and optionally the path to a config file."
  exit(1)
end




# load the root
require 'pathname'
root = Pathname.new(ARGV[0])
if not File.exist?(root) and File.directory?(root)
  $stderr.puts "The path provided is not a directory.  Cannot serve from '#{root}'"
  exit(1)
end



# Load settings, if possible
require './engine/settings.rb'
settings = ARGV[1] || "settings.yml"
$stderr.puts "Settings file chosen does not exist, continuing using default settings.  The file will be written when settings are next saved (or when the server is stopped)." if not File.exist?(settings)
$s = RestrictiveSettings.new(mandatory, defaults, nil, settings, true)



# construct the wixi root system
require './engine/wixi.rb'
wixi_options = {:macro_start                  => $s[:macro_start],
                :macro_end                    => $s[:macro_end],
                :end_preamble                 => $s[:end_preamble],
                :template_content_placeholder => $s[:template_content_placeholder],
                :sanitise_utf8                => $s[:sanitise_utf8],
                :ext                          => $s[:ext],
                :build_dir_prefix             => $s[:build_dir_prefix]}
wixi = WiXi.new( root, $s[:compilers], $s[:compiler_dir], $s[:macros], $s[:macro_dir], wixi_options)



# construct a server servingthe root
require './serve/server.rb'
server = WiXServer.new( wixi )
server.serve( $s[:port], $s[:bind_address], $s[:ht_resource_path], $s[:url_static_root], $s[:url_resources], $s[:url_dynamic])



## Save settings
#puts "Saving settings before exit..."
#$s.save
#puts "Done.  Goodbye!"


puts "Goodbye!"
