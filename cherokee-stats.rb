#!/usr/bin/env ruby
# Author: Sergio Aguilar
# email: chekolyn@gmail.com
# Date: 12.23.2011 10:13:52
#
# Description:
# Verifies that the Domains listed on Cherokee community page
# http://www.cherokee-project.com/community.html
#
# Checks that the domain are registered and active
# Checks that the webserver is responding and running Cherokee
#
#---

# Required libraries:
require 'net/http'
require 'uri'
require 'thread'
require 'csv'
require_relative 'crawl'

#These value may vary in the future depending on the html sctructure of the file
$webpage = 'http://www.cherokee-project.com/community.html'
$match_begin = 'class="domain domain-PR0">'
$match_end = '<\/div>' #we have to scape the / with \ for RegEx
$csv_file_name = 'cherokee-stats-data.csv'

# Geo data location 
$geo_data = '/usr/share/GeoIP/GeoIP.dat'

# Data to perform a small test:
$test_data= ['0x00c0ffee.com', 'cad.uach.mx', 'bugs.cherokee-project.com', '0x50.org', '1mayi.com', '1van.org.ua']




def get_community(uri)  
  http = Net::HTTP.new(uri.host, uri.port)
  response = http.request(Net::HTTP::Get.new(uri.request_uri))
  html = response.body
end


def extract_domains(text)
  #Using Global Variables
  match_begin = $match_begin
  match_end = $match_end
  
  #Extracting the domains with RegEx
  text.chomp.scan(/#{match_begin}(.+?)#{match_end}/).flatten 
  #flatten importan to it returns just one array 
  #(.+?) very important: represents any word (single domain) between match_begin and match_end the words we are looking for.
end

 def fetch_servers(dom_list)

  queue = Queue.new
  dom_list.each{|domain| queue << domain }

  server_info = []

  STDOUT.sync = true
  threads = []
  10.times do
    threads << Thread.new do
      while (domain= queue.pop(true) rescue nil)
        crawl = Crawl.new(domain)
        server = crawl.server
        host = crawl.lookup
        country= GeoIP.new($geo_data).country(host).country_name

        #puts "Domain: #{domain} Server: #{server} \n #{crawl.summary}"
        if ((queue.size%50)==0 && queue.size!=0)
          print "#{queue.size}.."
        end
        server_info.push(crawl.summary_hash)
        

      end
    end
  end

  threads.each {|t| t.join }
  
  return server_info
end

def csv_write(server_data)
  
  #Prepare the file:
  writer = CSV.open( $csv_file_name, 'w')
  
  #Generate the CSV headers:
  writer << ['domain','uri', 'host', 'code', 'server_full', 'server_name', 
                              'server_version', 'server_os', 'lookup_time', 'connect_time', 'country_name'
                              ]
  #Convert from hash, array
  server_data.each_entry { |dom| 
    
    #Current line:
    single_dom_array = []
    
    if (!dom.nil?)
    dom.each_entry { |head, value|
      
      # If null change for NA "not applicable"
      if (value.nil?)
        value = "NA"
      end
      single_dom_array.push(value)
    }
    
    #puts "Single Dom Array:"
    #puts single_dom_array
    
    #Add to the file, one line a the time:
    #ADD array to the CSV file:
    writer << single_dom_array
    end
    #output += CSV.generate_line([dom[:domain], dom[:uri], dom[:host], dom[:code], dom[:server_full], dom[:server_name],
    #                             dom[:server_version], dom[:server_os], dom[:lookup_time], dom[:connect_time], dom[:country_name] ])  
  }
   
  #Close the file:
  writer.close
  
end

if $0 == __FILE__
  

  # If testing, dont fetch the webpage, and crawl hundreds of domains
  if (ARGV[0] == "test")
    puts "Using test data domains:"
    dom_list = $test_data
  else
    #Open the Cherokee comunity page
    puts "Getting webpage community.html"
    uri = URI.parse($webpage)
    raw_text = get_community(uri)
    dom_list = extract_domains(raw_text)
  end
       
  puts "******************************************"
  puts "Domain List size: #{dom_list.size}"

  puts "Starting Server info fetch --->"
  
  puts "Servers remaining:"
  server_data = fetch_servers(dom_list)
  
  puts "Server_data size: #{server_data.length}"
  puts "Server_data class: #{server_data.class}"
  #puts server_data
  
  #Write to csv, parse the hashtable
  csv_write(server_data)
  
end