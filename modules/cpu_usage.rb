module CpuUsage
  def collection
    return @collection if @collection
    @collection = []

    cpu_usage = `cat /proc/loadavg`.split.first.to_f * 100
    @collection << {:name => "cpu_usage", :value => cpu_usage, :max => 100}
  end

  def os_support?
    true if RUBY_PLATFORM =~ /linux/i
  end
end
  