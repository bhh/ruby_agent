module NetworkCounter
  def collection
    return @collection if @collection
    @collection = []

    network_output = `cat /proc/net/dev`.split("\n")
    2.times{network_output.shift}
    network_output.each do |line|
      stats = line.strip.split(/[ :]+/)
      @collection << {:name => "net bytes #{stats[0].to_s}", :value => stats[1].to_f, :view_type => :delta}
      @collection << {:name => "net errs #{stats[0].to_s}", :value => stats[3].to_f, :view_type => :delta}
    end
    @collection
  end

  def os_support?
    true if RUBY_PLATFORM =~ /linux/i
  end
end