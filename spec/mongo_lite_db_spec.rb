require_relative '../mongo_lite_db.rb'
require 'fileutils'

describe MongoLiteDB do
  before(:all) do
    @filename = "rspec_test.mglite"
    @db = MongoLiteDB.new @filename
  end
  after(:all) do
    FileUtils.rm @filename
  end
  it "should initialize db file" do
    File.exists?(@filename).should be_true 
  end
 
  describe "when using a single object" do 
    before(:each) do
        @object = {"name" => "John", "age" => 18}
        @updated_object = {"name" => "John", "age" => 20} 
    end        
    it "should allow insertion" do
      @db.insert(@object)
    end
    it "should allow retrieval" do
      object = @db.find(@object).first
      object["name"].should eq("John")
      object["age"].should eq(18)
    end
    it "should allow update" do
      @db.update(@object, @updated_object)
      @db.find(@object).should be_empty
      @db.find(@updated_object).first["age"].should eq(20) 
    end
    it "should allow deletion" do
      @db.delete(@updated_object)
      @db.find(@updated_object).should be_empty
    end
  end
  describe "insert" do
    before(:each) do
      @db.delete({})
    end
    it "should add an id to record" do
      obj = {"age"=>25}
      @db.insert(obj)
      @db.find(obj).first["id"].should_not be_nil
    end
    it "should accept duplicate entries" do
      obj = {"apples"=>30}
      @db.insert(obj)
      @db.insert(obj)
      objs = @db.find(obj).count.should eq(2)
    end
    it "should autoincrement id on each insert" do
      obj = {"speed"=>30}
      @db.insert(obj)
      @db.insert(obj)
      objs = @db.find(obj)
      objs[0]["id"].should eq(objs[1]["id"] - 1)
    end
    it "should make a copy of object on insert" do
      obj = {"color" => "yellow"}
      obj_copy = obj.clone
      @db.insert(obj)
      obj.should eq(obj_copy)
    end
    it "should allow batch inserts" do
      objs = []
      objs << {"greeting" => "hello"}
      objs << {"greeting" => "heysann"}
      @db.insert(objs)
      @db.find({}).count.should eq(2)
    end
  end
  describe "find" do
    before(:each) do
        @db.delete({})
    end
    describe "$or operator" do
      it "should return entries that match either condition" do
        obj1 = {"name" => "peter"}
        obj2 = {"number" => 22}
        obj3 = {"number" => 24}
        @db.insert [obj1, obj2, obj3]
        @db.find({"$or" => [
            {"name" => "peter"},
            {"number" => 22} 
        ]}).count.should be(2)
      end
      it "should allow multiple conditions that are anded together" do
          obj1 = {"name" => "peter"}
          obj2 = {"number" => 22}
          obj3 = {"number" => 22, "age" => 25}
          @db.insert [obj1, obj2, obj3]
          @db.find({"$or" => [
              {"name" => "peter"},
              {"number" => 22, "age" => 25} 
          ]}).count.should be(2)
      end 
      it "should allow nested $or" do
          obj1 = {"name" => "peter"}
          obj2 = {"number" => 22}
          obj3 = {"number" => 22, "age" => 25}
          obj4 = {"number" => 22, "age" => 23}
          @db.insert [obj1, obj2, obj3, obj4]
          # (name=peter) OR (number=22 AND (age=23 OR age=25))
          @db.find({"$or" => [
            {"name"  => "peter"},
            {"number" => 22, "$or" => [
                {"age" => 23},
                {"age" => 25}
            ]}
          ]}).count.should eq(3)
      end
    end
    describe "$nor operator" do
        it "should return entries that do not match any of the conditions" do
            pending("just haven't done it yet")
        end
    end
    describe "$and operator" do
        it "should return entries that match all of the conditions" do
            pending("there's an implicit $and already and I don't want to take the time to do the explicit one yet")
        end
    end
    describe "$in operator" do
      it "should return entries that match any of the values" do
          obj1 = {"number" => 22, "age" => 25}
          obj2 = {"number" => 22, "age" => 23}
          obj3 = {"number" => 22, "age" => 27}
          @db.insert [obj1, obj2, obj3]
          @db.find({ "age" => { "$in" => [23, 25] } }).count.should eq(2)          
      end
    end
    describe "$nin operator" do
      it "should return entries that do not match given values" do
          obj1 = {"number" => 22, "age" => 25}
          obj2 = {"number" => 22, "age" => 23}
          obj3 = {"number" => 22, "age" => 27}
          @db.insert [obj1, obj2, obj3]
          @db.find({ "age" => { "$nin" => [23, 25] } }).count.should eq(1)
      end
    end
    describe "$exists operator" do
      it "should return entries that have the field defined when true" do
          obj1 = {"number" => 22}
          obj2 = {"number" => 22, "age" => 23}
          obj3 = {"number" => 22, "age" => 24}
          @db.insert [obj1, obj2, obj3]
          @db.find({ "age" => { "$exists" => true } }).count.should eq(2)
      end
      it "should return entries that do not have the field defined when false" do
          obj1 = {"number" => 22}
          obj2 = {"number" => 22, "age" => 23}
          obj3 = {"number" => 22, "age" => 24}
          @db.insert [obj1, obj2, obj3]
          @db.find({ "age" => { "$exists" => false } }).count.should eq(1)
      end
    end
    describe "numerical operations" do
      before(:each) do
          obj1 = {"number" => 22, "age" => 25}
          obj2 = {"number" => 22, "age" => 23}
          obj3 = {"number" => 22, "age" => 27}
          @db.insert [obj1, obj2, obj3]
      end
      describe "$gt" do 
          it "should return entries where field is greater than the value" do
              result = @db.find({"age" => { "$gt" => 25 } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(27).should_not be_nil
              matched_ages.empty?.should be_true
          end
      end
      describe "$gte" do 
          it "should return entries where field is greater than or equal to the value" do
              result = @db.find({"age" => { "$gte" => 25 } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(25).should_not be_nil
              matched_ages.delete(27).should_not be_nil
              matched_ages.empty?.should be_true
          end
      end
      describe "$lt" do 
          it "should return entries where field is less than the value" do
              result = @db.find({"age" => { "$lt" => 25 } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(23).should_not be_nil
              matched_ages.empty?.should be_true
          end
      end
      describe "$lte" do 
          it "should return entries where field is less than or equal to the value" do
              result = @db.find({"age" => { "$lte" => 25 } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(23).should_not be_nil
              matched_ages.delete(25).should_not be_nil
              matched_ages.empty?.should be_true
          end
      end
      describe "$ne" do 
          it "should return entries where field is not equal to the value" do
              result = @db.find({"age" => { "$ne" => 25 } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(23).should_not be_nil
              matched_ages.delete(27).should_not be_nil
              matched_ages.empty?.should be_true
          end
      end
      describe "$mod" do
        it "should entries where the field value divided by the divisor has the specified remainder" do
              result = @db.find({"age" => { "$mod" => [4,3] } })
              matched_ages = result.map{|r| r["age"]}
              matched_ages.delete(23).should_not be_nil
              matched_ages.delete(27).should_not be_nil
              matched_ages.empty?.should be_true
        end
      end
    end
    it "should support multiple keyword conditions" do
      obj1 = {"number" => 22}
      obj2 = {"number" => 22, "age" => 23}
      obj3 = {"number" => 22, "age" => 24}
      obj4 = {"number" => 22, "age" => 25}
      @db.insert [obj1, obj2, obj3, obj4]
      @db.find({ "age" => { "$exists" => true, "$nin" => [23,24] } }).count.should eq(1)
    end  
  end
end
