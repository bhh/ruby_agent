require 'rubygems'
require 'net/http'
require 'rexml/document'
include REXML
require 'builder'
require 'active_support'

url = URI.parse('http://example.url.at/entries.xml')
request = Net::HTTP::Post.new(url.path)
request['Content-Type'] = "application/xml"
request['X-Requested-With'] = "XmlHttpRequest"

transmit = [:cpu_usage, :mem_buffers, :mem_cached, :mem_usage, :mem_free]

while(true)
  cpu_usage = `cat /proc/loadavg`.split.first.to_f * 100 if transmit.include? :cpu_usage
  memory_stats = `cat /proc/meminfo`.split("\n").inject({}){|r,x| k,v = x.split(":"); r[k.underscore.to_sym] = v.strip.split.first.to_i; r} if (transmit & [:mem_buffers, :mem_cached, :mem_usage, :mem_free]).present?
  output = ""
  x = Builder::XmlMarkup.new(:target => output, :indent => 1)
  x.instruct!
  x.request do
    x.key "<user key>"
    x.host "<host key>"
    x.entry { x.key "mem_free"; x.value memory_stats[:mem_free] } if transmit.include? :mem_free
    x.entry { x.key "cpu"; x.value cpu_usage } if transmit.include? :cpu_usage
    x.entry { x.key "mem_buffers"; x.value memory_stats[:buffers] } if transmit.include? :mem_buffers 
    x.entry { x.key "mem_cached"; x.value memory_stats[:cached] } if transmit.include? :mem_cached
    x.entry { x.key "mem_usage"; x.value memory_stats[:mem_total] - memory_stats[:mem_free] } if transmit.include? :mem_usage
  end
  request.body = output

  response = Net::HTTP.start(url.host, url.port) {|http| http.request(request) }
#  puts response.inspect
  sleep 60
end
