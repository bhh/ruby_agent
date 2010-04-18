require 'rubygems'
require 'net/http'
require 'builder'
require 'active_support'

# Need to be filled in

user_key = ""
host_key = ""

# Transmitlist
transmit = [:cpu_usage, :mem_buffers, :mem_cached, :mem_usage, :mem_free, :disk_space]

# Script parameter
disks_regex = [/[sh]d[a-d][1-9]+/, %r(/dev/)]

url = URI.parse('http://monitor.ttech.at/entries.xml')
request = Net::HTTP::Post.new(url.path)
request['Content-Type'] = "application/xml"
request['X-Requested-With'] = "XmlHttpRequest"



while(true)
  xml_output = ""
  entries = []
  GC.start
  sleep 60
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
    entries << {:name => "mem_free", :value => memory_stats[:mem_free]}.merge!(mem_default) if transmit.include? :mem_free
    entries << {:name => "mem_usage", :value => (memory_stats[:mem_total] - memory_stats[:mem_free])}.merge!(mem_default) if transmit.include? :mem_usage
    entries << {:name => "mem_cached", :value => memory_stats[:cached]}.merge!(mem_default) if transmit.include? :mem_cached
    entries << {:name => "mem_buffers", :value => memory_stats[:buffers]}.merge!(mem_default) if transmit.include? :mem_buffers
  end

  # disks
  if transmit.include? :disk_space
    disk_list = %x(df -P).split("\n")
    disk_list.shift
    disk_list.each do |line|
      line = line.split
      if disks_regex.detect{|x| line[0].to_s.match(x)}
        entries << {:name => "disk usge #{line[0]}", :value => line[2], :max => line[1]}
        #puts ["disk percent #{line[0]}", line[4].to_i]
      end
    end
  end

  # Add entries


  # XML Request

  x = Builder::XmlMarkup.new(:target => xml_output, :indent => 0)
  x.instruct!
  x.request do
    x.configuration do
      x.version 1.0
      x.key user_key
      x.host host_key
    end
    for entry in entries
      x.entry do
        x.key entry[:name].to_s
        x.value entry[:value].to_f
        x.max entry[:max].to_f if entry[:max]
      end
    end
  end
  request.body = xml_output

  # TODO Store for later use if entries were not created
  Net::HTTP.start(url.host, url.port) {|http| http.request(request) }
end
