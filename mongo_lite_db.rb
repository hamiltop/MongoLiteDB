require 'json'
require 'pry'

class MongoLiteDB
    def initialize(filename="db.nsl")
        @filename = filename
        if not File.exists?(@filename)
            open(@filename, 'w'){|f| f.write(
                {
                    "max_index" => 0,
                    "objects" => []
                }.to_json
            )}
        end
    end
    def insert(objects)
        if not objects.kind_of?(Array)
           objects  = [objects]
        end
        write_to_disk do |db|
            objects.each do |object|
                object_copy = object.clone
                object_copy["id"] = db["max_index"]
                db["max_index"] += 1
                db["objects"] << object_copy
            end
        end
    end
    def find(query)
        entries = []
        load_from_disk do |db|
            each_match(db, query) do |obj|
                entries << obj
            end  
        end
        return entries
    end
        
    def update(query, attr)
        write_to_disk do |db|
            each_match(db, query) do |obj|
                obj.update(attr) 
            end 
        end     
    end
    def delete(query)
        write_to_disk do |db|
            each_match(db, query) do |obj|
                db["objects"].delete(obj)
            end
        end
    end

    private
    def write_to_disk
        f = open(@filename, 'r+')
        f.flock(File::LOCK_EX)
        db = JSON.parse f.read
        yield db
    ensure
        if f
            if db
                f.rewind
                f.write db.to_json
                f.flush
                f.truncate f.pos
            end
            f.close
        end
    end

    def load_from_disk
        f = open(@filename, 'r+')
        f.flock(File::LOCK_SH)
        db = JSON.parse f.read
        yield db
    ensure
        if f
            f.close
        end 
    end

    def each_match(db, query)
        db["objects"].clone.each do |obj|
            yield(obj) unless not match(obj, query)
        end
    end

    def match(obj, query)
        # query is either an array in the form of [key, value] or a hash
        # if query is an Array, key is a string, value can be anything
        #   if value is an array, we should expect a keyword for key
        #   if value is an hash, we should expect it's only key to be a keyword
        #   if value is a string or FixNum , we should check for attribute match
        # if query is Hash, then we break it into individual queries and recursively call them (as arrays)
        if query.kind_of? Array
            if query[1].kind_of? Array
                case query[0]
                when "$or"
                    match = false
                    query[1].each do |attr|
                        is_a_match = match(obj, attr)
                        match ||= is_a_match
                    end
                    return match
                else
                    raise NotImplementedError
                end
            elsif query[1].kind_of? Hash
                match = true
                query[1].each do |k,v|
                    case k
                    when "$in"
                        local_match = false
                        v.each do |value|
                            is_a_match = match(obj, [query[0], value])
                            local_match ||= is_a_match
                        end
                        match &&= local_match
                    when "$exists"
                        match &&= (not obj[query[0]].nil?) == v
                    when "$nin"
                        local_match = true
                        v.each do |value|
                            is_a_match = match(obj, [query[0], value])
                            local_match &&= (not is_a_match)
                        end
                        match &&= local_match
                    when "$gt"
                        return obj[query[0]] > v
                    when "$gte"
                        return obj[query[0]] >= v
                    when "$lt"
                        return obj[query[0]] < v
                    when "$lte"
                        return obj[query[0]] <= v
                    when "$ne"
                        return obj[query[0]] != v
                    when "$mod"
                        return obj[query[0]] % v[0] == v[1]
                    else
                        raise NotImplementedError
                    end
                end
                return match
            else
                match = (obj[query[0]] == query[1])
                return match
            end
        elsif query.kind_of? Hash
          match = true
          query.to_a.each do |attr|
              is_a_match = match(obj, attr)
              match &&= is_a_match
          end
          return match
        else
            raise NotImplementedError
        end
    end
end
