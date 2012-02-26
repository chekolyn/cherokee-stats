#!/bin/ruby

#---
# Verifies that the Domains listed on Cherokee community page
# http://www.cherokee-project.com/community.html
#
# Checks that the domain are registered and active
# Checks that the webserver is responding and running Cherokee
#
# TEST for script
#---

require 'test/unit' 
require_relative 'cherokee-stats'
require_relative 'crawl'

class CherokeeStatsTests < Test::Unit::TestCase 


  def test_extract_domains
    text_sample = '</div></div></div><div id="widget_1933258" class="domain_list"><ul id="widget_1933259" ><li id="widget_1933262" ><div id="widget_1933261" class="domain domain-PR0">0x00c0ffee.com</div></li><li id="widget_1933265" ><div id="widget_1933264" class="domain domain-PR0">0x00c0ffee.net</div></li><li id="widget_1933268" ><div id="widget_1933267" class="domain domain-PR0">0x00c0ffee.org</div></li><li id="widget_1933271" ><div id="widget_1933270" class="domain domain-PR0">0x50.org</div></li><li id="widget_1933274" ><div id="widget_1933273" class="domain domain-PR0">1mayi.com</div></li><li id="widget_1933277" ><div id="widget_1933276" class="domain domain-PR0">1van.org.ua</div> '
    
    expected = ['0x00c0ffee.com', '0x00c0ffee.net', '0x00c0ffee.org', '0x50.org', '1mayi.com', '1van.org.ua']
    assert_equal(expected, extract_domains(text_sample))
  end
  

end

class CrawlTests < Test::Unit::TestCase
  
  def test_crawl_basics    
    domain = "ln1.imakun.com"
    crawl = Crawl.new(domain)
    
    domain_expected = "ln1.imakun.com"
    server_expected = "Cherokee/1.2.101"
    assert_equal(domain_expected, crawl.domain)
    assert_equal(server_expected, crawl.server)
    #puts "Crawl Server: #{@crawl.server}"
    
    puts crawl.summary_print
  end
  
  def test_crawl_lookup
    domain = "ln1.imakun.com"
    crawl = Crawl.new(domain)
    
    puts crawl.lookup_time
  end
  
end