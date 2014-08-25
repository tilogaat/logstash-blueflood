# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Http < LogStash::Outputs::Base
  # This output lets you `PUT` or `POST` events to a
  # generic HTTP(S) endpoint
  #
  # Additionally, you are given the option to customize
  # the headers sent as well as basic customization of the
  # event json itself.

  config_name "blueflood"
  milestone 1

  # URL to use
  config :url, :validate => :string, :required => :true

  # validate SSL?
  #config :verify_ssl, :validate => :boolean, :default => true

  # What verb to use
  # only put and post are supported for now
  # config :http_method, :validate => ["post"], :required => :true

  # Custom headers to use
  # format is `headers => ["X-My-Header", "%{host}"]
  #config :headers, :validate => :hash

  # Content type
  #
  # If not specified, this defaults to the following:
  #
  # * if format is "json", "application/json"
  # * if format is "form", "application/x-www-form-urlencoded"
  config :content_type, :validate => :string, :default => "application/json"
  
  config :port, :validate => :string	
  config :tenant_id, :validate => :string	

  # This lets you choose the structure and parts of the event that are sent.
  #
  #
  # For example:
  #
  #    mapping => ["foo", "%{host}", "bar", "%{type}"]
  #config :mapping, :validate => :hash

  # Set the format of the http body.
  #
  # If form, then the body will be the mapping (or whole event) converted
  # into a query parameter string (foo=bar&baz=fizz...)
  #
  # If message, then the body will be the result of formatting the event according to message
  #
  # Otherwise, the event is sent as json.
  config :format, :validate => ["json"], :default => "json"

  #config :message, :validate => :string

  public
  def register
    require "ftw"
    require "uri"
    @agent = FTW::Agent.new
    @url = url+":"+port+"/v2.0/"+tenant_id+"/ingest"
  end # def register

  public
  def receive(event)
    return unless output?(event)

    case @http_method
    	when "post"
		request = @agent.post(event.sprintf(@url))
    	else
      		@logger.error("Unknown verb:", :verb => @http_method)
    end
    request["Content-Type"] = @content_type

    begin
      if @format == "json"
        request.body = evt.to_json
      end
      response = @agent.execute(request)

      # Consume body to let this connection be reused
      rbody = ""
      response.read_body { |c| rbody << c }
      #puts rbody
    rescue Exception => e
      @logger.warn("Unhandled exception", :request => request, :response => response, :exception => e, :stacktrace => e.backtrace)
    end
  end # def receive
end
