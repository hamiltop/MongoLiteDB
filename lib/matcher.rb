require 'predicate_matcher'

class Matcher
  def initialize(query)
    @query = query
  end

  def match(obj)
    if @query.length > 1
      # We always have an implied $and for multiple entries
      matcher = AndMatcher.new({"$and" => @query.map{|k,v| {k => v}}})
    elsif @query.length == 0
      matcher = EmptyMatcher.new(@query)
    else 
      # we only have one entry
      case @query.keys.first
      when "$or"
        matcher = OrMatcher.new(@query)
      when "$nor"
        matcher = NorMatcher.new(@query)
      when "$and"
        matcher = AndMatcher.new(@query)
      else
        matcher = AttrMatcher.new(@query)
      end
    end
    return matcher.match(obj)
  end
end

class AttrMatcher < Matcher
  def match(obj)
    attribute = @query.keys.first
    if attribute.include?(".")
      value = obj
      attribute.split(".").each do |attr|
        value = value[attr]
        if value.nil?
          return false
        end
      end
    else
      value = obj[@query.keys.first]
    end
    predicate = @query.values.first
    if predicate.kind_of? Hash
      matcher = PredicateMatcher.new(predicate)
      return matcher.match(value)
    else
      return value == predicate
    end
  end
end

class AndMatcher < Matcher
  def match(obj)
    does_it_match = true 
    @query.values.first.each do |subquery|
      matcher = Matcher.new(subquery)
      does_it_match &&= matcher.match(obj) 
    end  
    return does_it_match
  end 
end

class EmptyMatcher < Matcher
  def match(obj)
    true
  end
end

class OrMatcher < Matcher
  def match(obj)
    does_it_match = false
    @query.values.first.each do |subquery|
      matcher = Matcher.new(subquery)
      does_it_match ||= matcher.match(obj)
    end
    return does_it_match
  end
end

class NorMatcher < Matcher
  def match(obj)
    return !OrMatcher.new(@query).match(obj)
  end
end
