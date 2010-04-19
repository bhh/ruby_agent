module Memory
  def self.extended
    @memory_stats = `cat /proc/meminfo`.split("\n").inject({}){|r,x| k,v = x.split(":"); r[k.underscore.to_sym] = v.strip.split.first.to_i; r}
    @collection = []
  end

  def collection
    mem_default = {:max => @memory_stats[:mem_total]}
    @collection << {:name => "mem_usage", :value => (@memory_stats[:mem_total] - @memory_stats[:mem_free])}.merge!(mem_default)
    @collection << {:name => "mem_cached", :value => @memory_stats[:cached]}.merge!(mem_default)
    @collection << {:name => "mem_buffers", :value => @memory_stats[:buffers]}.merge!(mem_default)
  end

  def os_support?
    true if RUBY_PLATFORM =~ /linux/i
  end
end
