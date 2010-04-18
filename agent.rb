require 'rubygems'
require 'net/http'
require 'rexml/document'
include REXML
require 'builder'
require 'active_support'

url = URI.parse('http://example.at/entries.xml')
request = Net::HTTP::Post.new(url.path)
request['Content-Type'] = "application/xml"
request['X-Requested-With'] = "XmlHttpRequest"

transmit = [:cpu_usage, :mem_buffers, :mem_cached, :mem_usage, :mem_free, :disk_space]
disks = [/[sh]d[a-d][1-9]+/]
user_key = ""
host_key = ""
entries = []

while(true)
  # Scripts
  # cpu
  if transmit.include? :cpu_usage
    cpu_usage = `cat /proc/loadavg`.split.first.to_f * 100
    entries << {:name => "cpu_usage", :value => cpu_usage, :max => 100}
  end

  # memory
  unless (transmit & [:mem_buffers, :mem_cached, :mem_usage, :mem_free]).empty?
    memory_stats = `cat /proc/meminfo`.split("\n").inject({}){|r,x| k,v = x.split(":"); r[k.underscore.to_sym] = v.strip.split.first.to_i; r}
    mem_default = {:max => memory_stats[:mem_total]}
    entries << mem_default.merge!({:name => "mem_free", :value => memory_stats[:mem_free]}) if transmit.include? :mem_free
    entries << mem_default.merge!({:name => "mem_usage", :value => (memory_stats[:mem_total] - memory_stats[:mem_free])}) if transmit.include? :mem_usage
    entries << mem_default.merge!({:name => "mem_cached", :value => memory_stats[:cached]}) if transmit.include? :mem_cached
    entries << mem_default.merge!({:name => "mem_buffers", :value => memory_stats[:buffers]}) if transmit.include? :mem_buffers
  end

  # disks
  if transmit.include? :disk_space
    disk_list = %x(df -P).split("\n")
    disk_list.shift
    disk_list.each do |line|
      line = line.split
      if disks.detect{|x| line[0].to_s.match(x)}
        entries << {:name => "disk usge #{line[0]}", :value => line[2], :max => line[3]}
        #puts ["disk percent #{line[0]}", line[4].to_i]
      end
    end
  end

  # Add entries


  # XML Request
  output = ""
  x = Builder::XmlMarkup.new(:target => output, :indent => 0)
  x.instruct!
  x.request do
    x.key user_key
    x.host host_key
    for entry in entries
      x.entry do
        x.key entry[:name].to_s
        x.value entry[:value].to_f
        x.max entry[:max].to_f if entry[:max]
      end
    end
  end
  request.body = output

  # TODO Store for later use if entries were not created
  response = Net::HTTP.start(url.host, url.port) {|http| http.request(request) }

  sleep 60
end
