require 'net/http'
require 'uri'
require 'resolv'
require 'geoip'

class Crawl

  attr_accessor :domain, :timeout
  attr_reader :uri, :host, :server, :request, :response, :connect_time, :lookup_time
  
  def initialize(domain)    
    @connect_time_begin, @connect_time_end, @lookup_time_begin, @lookup_time_end = nil
    
    @domain = domain
    @timeout = 1
    @uri = URI.parse("http://#{@domain}/")
  end
  
  def domain=(domain)
    @domain = domain
    @uri = URI.parse("http://#{@domain}/")
  end
  
  def head
    begin
      http = Net::HTTP::new(uri.host, uri.port)
      http.open_timeout, http.read_timeout = @timeout
      
      #request = Net::HTTP::Get.new(uri.request_uri)
      @connect_time_begin = Time.now
      @request = Net::HTTP::Head.new(uri.request_uri)
      
      #Will just return the server headers
      @response = http.request(request)    
      @connect_time_end = Time.now
      #See https://github.com/augustl/net-http-cheat-sheet/blob/master/response.rb for other options
        
      return @response
    rescue Exception => ex
      @response = nil
    end
  end
  
    def get
    begin
      http = Net::HTTP::new(uri.host, uri.port)
      http.open_timeout, http.read_timeout = @timeout
      
      #request = Net::HTTP::Get.new(uri.request_uri)
      @connect_time_begin = Time.now
      @request = Net::HTTP::Get.new(uri.request_uri)
      
      #Will just return the server headers
      @response = http.request(request)
            
      @connect_time_end = Time.now
      #See https://github.com/augustl/net-http-cheat-sheet/blob/master/response.rb for other options

    rescue Exception => ex
      @response = nil
    end
  end
  
  def lookup
    @lookup_time_begin = Time.now
    begin
      @host = Resolv.new.getaddress(@domain)
    rescue Exception => ex
      @host = nil
    end  
    @lookup_time_end = Time.now
     return @host
  end
  
  def country_name
    country= GeoIP.new($geo_data).country(@host).country_name
  end
  
  def summary_hash
    if !@response.nil?
      info_hash = {:domain=> @domain, :uri=>@uri.to_s, :host=>@host, :code=>@response.code, :server_full=>server,:server_name=>server_name,
                   :server_version=>server_version, :server_os=>server_os, :lookup_time=>lookup_time, 
                   :connect_time=>connect_time, :country_name=>country_name }
    else
      nil
    end  
  end
  
  def summary_print
    if !@response.nil?
      info_hash = summary_hash
      text = "Summary: URI=#{@uri} Host:#{@host} Code:#{@response.code} Server:#{@server} Lookup-time: #{lookup_time} ms Connect-time:#{connect_time} ms Country:#{country_name}"
    else
      text = "Summary: No Web response"
    end
  end
  
  def connect_time
    if !@domain.nil?
      connect_time = "%.2f" % ((@connect_time_end - @connect_time_begin) * 1000)
    else
      nil
    end
      
  end
  
  def lookup_time
    if !@host.nil?
    lookup_time = "%.2f" % ((@lookup_time_end - @lookup_time_begin) * 1000)
    else
      nil
    end  
  end
  
  def get_server
    get_head = head
    
    if !get_head.nil?
      get_head["Server"]
    else
      nil
    end
  end
  
  def server
    # Fetch only once:
    if (@server.nil?)
      @server = get_server
      #puts "Server fetched---->"
    else
      @server
    end
  end
  
 def server_name
   if (!@server.nil?)
    #@server.scan(/(\S+)\//).flatten[0] old -- kinda works
    @server.scan(/^(\w+)/).flatten[0]
   end
  end

  def server_version
    if (!@server.nil?)
      @server.chomp.scan(/^\S+\/(\S+)/).flatten[0]
    end   
  end

  def server_os
    if (!@server.nil?)
      @server.chomp.scan(/^\S+\/\S+\s\((.+)\)$/).flatten[0]
    end
  end
  
  def to_s
    summary_print
  end
   
end