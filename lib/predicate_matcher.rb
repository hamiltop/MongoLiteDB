class PredicateMatcher
  def initialize(predicate)
    @predicate = predicate
  end
  def match(value)
    if @predicate.length > 1
      matcher = AndPredicateMatcher.new(@predicate)
      return matcher.match(value)
    end
    case @predicate.keys.first
    when "$exists"
      return @predicate.values.first == !value.nil? 
    when "$in"
      return @predicate.values.first.include?(value)
    when "$nin"
      return !@predicate.values.first.include?(value)
    when "$gt"
      return value > @predicate.values.first
    when "$gte"
      return value >= @predicate.values.first
    when "$lt"
      return value < @predicate.values.first
    when "$lte"
      return value <= @predicate.values.first
    when "$ne"
      return value != @predicate.values.first
    when "$mod"
      return value % @predicate.values.first[0] == @predicate.values.first[1]
    else
      raise NotImplementedError
    end  
  end
end

class AndPredicateMatcher < PredicateMatcher
  def match(value)
    does_it_match = true
    @predicate.each do |k,v|
      matcher = PredicateMatcher.new({k => v})  
      does_it_match &&= matcher.match(value)
    end
    return does_it_match
  end
end

