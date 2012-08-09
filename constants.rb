#####################################################################
# Server Options
#####################################################################
# Where to serve?
#-- PORT            = 10000 

# Bind to a particular interface?
# use nil for all interfaces
#BIND_ADDRESS    = "127.0.0.1"
#--BIND_ADDRESS    = nil

# URIPaths relative to the hostname root for content:
#
# > Static Root -- Where static resources are to be found for download
# > Resources   -- CSS and other page resources
# > Dynamic     -- Root of the wiki content driven by the engine "wiki" in wikipedia, for example
#--URL_STATIC_ROOT = "static"
#--URL_RESOURCES   = "resources"
#--URL_DYNAMIC     = ""

# Templating Engine internals
#
# The basic template is augmented using subtemplates.
# These should not require editing in most instances.
#--TEMPLATE_DIR      = "./resources/template/"
#--DEFAULT_TEMPLATE  = "default.erb"
#--SUB_TEMPLATES     = {"edit"     => "edit.erb",
                     #"display"  => "display.erb",
                     #"compile"  => "compile.erb",
                     #"delete"   => "delete.erb",
                     #"upload"   => "upload.erb",
                     #"search"   => "search.erb"}

# Filepaths for resources
# HT resource is where the URL_RESOURCES links to.
#--HT_RESOURCE_PATH  = "htresources"
# RESOURCE_PATH is where URL_STATIC_ROOT links to.
#--RESOURCE_PATH     = "resources"

# Plugins
#--MACRO_DIR         = "macros"
#--COMPILER_DIR      = "compilers"

# The extension used by page content files.
#--EXT               = "wtex"

# Use iconV to strip invalid UTF8 strings?
# If set to true, requires the iconv gem.  I _strongly_ recommend true.
#--SANITISE_UTF8     = true

#####################################################################
# Compiler Options
#####################################################################
# Compilers must subclass Compiler to be initalised.
# The names are not escaped, so don't use any URL or HTML breaking features.
#--COMPILERS = {   "Download"   => {:class => "PDFDownloadCompiler",  :file => "pdf_download_compiler.rb"},
                #"Embed"      => {:class => "PDFEmbedCompiler",     :file => "pdf_embed_compiler.rb"},
               ##"Plain"      => {:class => "PlainTextCompiler",    :file => "plain_text_compiler.rb"},
               ##"Hevea"      => {:class => "HeveaCompiler",        :file => "hevea_compiler.rb"},
                #"LaTeX2HTML" => {:class => "LaTeX2HTMLCompiler",   :file => "latex_html_compiler.rb"},
               ##"DeTeX"      => {:class => "DeTeXCompiler",        :file => "detex_compiler.rb"},
               ##"PlasTeX"    => {:class => "PlasTexCompiler",      :file => "plastex_compiler.rb"},
                #"TtH"        => {:class => "TTHCompiler",          :file => "tth_compiler.rb"}
            #}

# Which compiler (of the above) to use by default
# Templates are always rendered as plaintext.
#--DEFAULT_COMPILER  = "LaTeX2HTML"

# Command to run against LaTeX2HTML.  Must output one HTML file in 
# the build dir.  
#
# Args: %s -- The full pathname to a tex file.
#--CMD_LATEX2HTML    = "latex2html -split 0 -noaddress -noinfo -nonavigation -nosubdir \"%s\""
# if set to true, will copy the output images from latex2html.
# LaTeX2HTML is slow at generating images, so this is disabled by default 
# (and you may clobber files when copying back img[0-9]+.png)
#
# PUT -noimages in the CMD_LATEX2HTML config to speed up rendering.
#--COPY_LATEX2HTML_IMAGES = true  

# Command to run hevea.  Must take TeX on stdin and output HTML on 
# stdout
#CMD_HEVEA         = "hevea -s"

# DeTeX command, passed a filename and expected to output to stdout
#CMD_DETEX         = "detex \"%s\""

# TTh output, passed a filename and expected to output to stdout
#CMD_TTH           = "tth -u -a -r  < \"%s\""

# PDFLatex command.
# 
# Args: %s -- The build (temp) directory 
#       %s -- The full LaTeX file path
#CMD_PDFLATEX      = "pdflatex -interaction=batchmode -output-directory=\"%s\" \"%s\""
#CMD_PDFBIBTEX     = "bibtex \"%s\""

# Should the pdf compiler try to resolve bibtex references?
#PDFLATEX_TRIPLE_COMPILE = true

# The prefix to use for the temporary compile directory in $TEMP
# i.e. $TEMP/BUILD_DIR_PREFIX/Path/To/Page/Page.tex
#BUILD_DIR_PREFIX  = "wixicompile"

# The template to render template data onto the page using.
# This should contain a few simple styles and not much else.
#TEMPLATE_RENDER_CONTAINER     = "%s" # html
#PLAINTEXT_RENDER_CONTAINER    = "<div style=\"font-family: monospace; white-space: pre-wrap;\">%s</div>" # html
#DETEX_RENDER_CONTAINER        = "<div style=\"font-family: monospace; white-space: pre-wrap;\">%s</div>" # html
#PDF_DOWNLOAD_RENDER_CONTAINER = "<h3>Download</h3><p>Download <a target=\"_blank\" href=\"%s\">%s</a></p>" # file uri, basename
#PDF_EMBED_RENDER_CONTAINER    = "

#<script type=\"text/javascript\"> 
#function resizeFrame(){ 
    #newheight=Math.max(window.innerHeight - 150, 100);
    #document.getElementById('pdfarea').style.height = newheight + \"px\"; 
#}

#window.onresize=resizeFrame;
#window.onload=resizeFrame;
#</script> 

#<iframe onclick=\"resizeFrame\" id=\"pdfarea\" class=\"pdfembed\" src=\"%s\"></iframe>" #file uri

#####################################################################
# Editing/Content Options
#####################################################################
# Where do we inject the content in a template?
# Look for this string on a line of its own.
# Changing this after content is written will break everything.
#--TEMPLATE_CONTENT_PLACEHOLDER = "%content%"

# Page Defaults
#
# The default page to open if no path is given
#--DEFAULT_PAGE      = "Home"

# The template suggested in a new page
#TEMPLATE_PAGE     = "Templates/Report" DEPRECATED

# The preamble used to define which template to use.
# Anything after this is taken as a template path and used for compiling.
#--CLASS_PREAMBLE    = "%class:" DEPRECATED
#--END_PREAMBLE      = "%----"


#http://rubybrain.com/api/ruby-1.9.0.2/doc/index.html?a=C00000246&name=CommandProcessor
# Macros may be called in any document.
# They comprise shell-like lists thus:
#
# MACRO_START command argument argument argument MACRO_END
#
# i.e.
# %macro{{{file_listing "/home/extremetomato/a directory" 14}}}
#--MACRO_START       = "%macro{{{"
#--MACRO_END         = "}}}"

#--REGISTERED_MACROS = { "CurrentDate"   => "current_date.rb",
                      #"EvalRuby"      => "eval_ruby.rb",
                      #"EditDate"      => "edit_date.rb",
                      #"PageMetadata"  => "page_metadata.rb",
                      #"References"    => "references.rb",
                      #"ListMacros"    => "list_macros.rb"}

# The string to enter in the delete page form.
#--DELETE_CONFIRM    = "ConfirmDelete"

# relpath (wiki path) of base file to search within from the sidebar.
#--BASE_SEARCH_DIR   = ""

# Error handler message.
#--ERROR_MSG         = "ERROR: %s:\n\n%s"

# Default contents of a new page.
#--DEFAULT_EDIT_CONTENTS = "%template: Templates/Article
##{END_PREAMBLE}
#
#\\author{Stephen Wattam}
#\\title{}
#\\maketitle
#
#
##{MACRO_START}References#{MACRO_END}
#"

# Converter from html to latex, must outut to stdout.
# The argument is the path to the downloaded html file.
#--CMD_HTML2LATEX    = "gnuhtml2latex -s %s" 
# wget to download the html for the converter
# argument 1 is the output filepath, argument 2 is the url
#--CMD_WGET_HTML2LATEX = "wget -q -k -O %s %s"

# Highlight LaTeX templates nicely, or leave them as plaintext?
#--USE_INK_SYNTAX_HIGHLIGHTING = false 

# Title to use for title and heading
#--APP_TITLE         = "Wi&chi;i"
