MongoLiteDB
===========

[![Build Status](https://travis-ci.org/hamiltop/MongoLiteDB.png)](https://travis-ci.org/hamiltop/MongoLiteDB)

An embeddable file based Mongo compatible database. Think SQLite for NoSQL.

For right now, I'll document the features by pasting the Rspec -f doc output

    rspec -f doc spec/mongo_lite_db_spec.rb

    MongoLiteDB
      should initialize db file
      when using a single object
        should allow insertion
        should allow retrieval
        should allow update
        should allow deletion
      insert
        should add an id to record
        should accept duplicate entries
        should autoincrement id on each insert
        should make a copy of object on insert
        should allow batch inserts
      find
        should support multiple keyword conditions
        $or operator
          should return entries that match either condition
          should allow multiple conditions that are anded together
          should allow nested $or
        $nor operator
          should return entries that do not match any of the conditions (PENDING: just haven't done it yet)
        $and operator
          should return entries that match all of the conditions (PENDING: there's an implicit $and already and I don't want to take the time to do the explicit one yet)
        $in operator
          should return entries that match any of the values
        $nin operator
          should return entries that do not match given values
        $exists operator
          should return entries that have the field defined when true
          should return entries that do not have the field defined when false
        numerical operations
          $gt
            should return entries where field is greater than the value
          $gte
            should return entries where field is greater than or equal to the value
          $lt
            should return entries where field is less than the value
          $lte
            should return entries where field is less than or equal to the value
          $ne
            should return entries where field is not equal to the value
          $mod
            should entries where the field value divided by the divisor has the specified remainder

    Pending:
      MongoLiteDB find $nor operator should return entries that do not match any of the conditions
        # just haven't done it yet
        # ./spec/mongo_lite_db_spec.rb:117
      MongoLiteDB find $and operator should return entries that match all of the conditions
        # there's an implicit $and already and I don't want to take the time to do the explicit one yet
        # ./spec/mongo_lite_db_spec.rb:122
