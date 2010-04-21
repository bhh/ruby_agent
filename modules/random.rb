module Random
  def collection
    return @collection if @collection
    @collection = []
    @collection << {:name => "random", :value => rand * 100, :max => 100, :view_type => Transmission::Component::DELTA_ABS}
  end

  def os_support?
    true
  end
end