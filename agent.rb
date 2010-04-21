require 'rubygems'
require 'net/http'
require 'builder'
require 'active_support'
require 'yaml'

class Transmission
  class Component
    
  end

  def initialize(*args)
    options = args.extract_options!
    raise ArgumentError if options["key"].nil?
    raise ArgumentError if options["host"].nil?

    @@url ||= URI.parse('http://monitor.ttech.at/entries.xml')
    @@request ||= Net::HTTP::Post.new(@@url.path)
    @@request['Content-Type'] ||= "application/xml"
    @@request['X-Requested-With'] ||= "XmlHttpRequest"
    @@key ||= options["key"]
    @@host ||= options["host"]
    @@exclude_module_list ||= options["exclude_modules"] || []
    @@exclude_variables_list ||= options["exclude_variables"] || []
    @entries = []
  end

  def generate_xml
    xml_output = ""
    x = Builder::XmlMarkup.new(:target => xml_output, :indent => 0)
    x.instruct!
    x.request do
      x.configuration do
        x.version 1.0
        x.key @@key
        x.host @@host
      end
      for entry in @entries
        x.entry do
          x.key entry[:name].to_s
          x.value entry[:value].to_f
          x.max entry[:max].to_f if entry[:max]
          x.view_type entry[:view_type].to_f if entry[:view_type]
        end
      end
    end
    @@request.body = xml_output
  end



  def set_entries
    Dir[File.join(File.dirname(__FILE__), 'modules', '*.rb' )].each do |file|
      basename = File.basename(file, File.extname(file))
      next if @@exclude_module_list.include?(basename)

      begin
        load file
        component = Component.new.extend basename.camelize.constantize
        @entries += component.collection.reject{|x| @@exclude_variables_list.include?(x[:name].to_s)} if component.os_support?
      rescue Exception
        $stderr.print "Please try again"
      end
    end
  end

  def deliver
    set_entries
    generate_xml
    # TODO Store for later use if entries were not created
    Net::HTTP.start(@@url.host, @@url.port) {|http| http.request(@@request) }
  end
end

while(true)
  GC.start
  sleep 60

  config = YAML.load_file(File.join(File.dirname(__FILE__),'config.yml'))
  transmission = Transmission.new(config)
  transmission.deliver
end
