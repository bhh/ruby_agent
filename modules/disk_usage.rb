module DiskUsage
  def self.extended
    @disks_regex = [/[sh]d[a-d][1-9]+/, %r(/dev/)]
    @disk_list = %x(df -P).split("\n")
    @disk_list.shift
    @collection = []
  end

  def collection
    @disk_list.each do |line|
      line = line.split
      if @disks_regex.detect{|x| line[0].to_s.match(x)}
        @collection << {:name => "disk usge #{line[0]}", :value => line[2], :max => line[1]}
      end
    end
    @collection
  end
  
  def os_support?
    true if RUBY_PLATFORM =~ /linux/i
  end
end


