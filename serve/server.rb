require 'webrick'
require './serve/wikcgi.rb'

class WikSimple < WEBrick::HTTPServlet::AbstractServlet

  def initialize(server, options={})
    super(server, options)
    @handler = options[:wiki_handler]
  end

  def do_GET(request, response)
    status, content_type, body, cookies = @handler.get(request)
    return build_response( response, status, cookies, content_type, body )
  end

  def do_POST(request, response)
    status, content_type, body, cookies =  @handler.post(request)
    return build_response( response, status, cookies, content_type, body )
  end

  private

  # build a response to the client from the given data
  def build_response( response, status, cookies, content_type, body )
    response.status           = status
    cookies.each{ |k,v|         response.cookies << "#{k}=#{v}" }
    response['Content-Type']  = content_type
    response.body             = body

    return response
  end
end




class WiXServer
  def initialize(wixi)
    @wixi = wixi
  end

  def serve(port, bind=nil, local_resource_path="", static="static", resources="resources", dynamic="")
    # repo path
    wikCGI = WikCGI.new(@wixi)
     
    # Serve the thing. 
    #if $0 == __FILE__ then
      server = WEBrick::HTTPServer.new(:Port        => port, 
                                       :BindAddress => bind)

      server.mount("/#{static}",        WEBrick::HTTPServlet::FileHandler, @wixi.root,               {:FancyIndexing => false})
      server.mount("/#{resources}",     WEBrick::HTTPServlet::FileHandler, local_resource_path, {:FancyIndexing => false})
      server.mount("/#{dynamic}",       WikSimple, {:wiki_handler => wikCGI})



      trap "INT" do server.shutdown end
      server.start
    #end

    
  end
end

