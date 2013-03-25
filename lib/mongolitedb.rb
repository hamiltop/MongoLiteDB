require 'json'
require 'matcher'

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
    matcher = Matcher.new(query)
    return matcher.match(obj)
  end
end
