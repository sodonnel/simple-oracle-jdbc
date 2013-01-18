module SimpleOracleJDBC

  # This module provides a wrapper around a JDBC result set object, allowing the result set to be returned
  # a row at a time, as an array or arrays or an array of hashes etc.
  #
  # Requires a instance variable called @result_set to be defined in the class
  # this module is included into. This should contain a JDBC result set object.

  module ResultSet

    # Retrieves the next row from the database and returns an array. Each element in the array
    # corresponds to a column in the select statement that created the result set.
    #
    # The value nil will be returned if there are no more rows to return, and the result set
    # will be closed.
    def next_array
      next_row
    end

    # Processes each row of the result set using the provided block, passing one row at a time
    # to the block as an array, eg:
    #
    #    obj.each_array do |r|
    #      # process the row
    #    end
    #
    # The result set will be closed when the method returns.
    def each_array(&blk)
      each_result true, &blk
    end

    # Consumes all the rows of the result set, and returns the result as an array of arrays.
    #
    # An empty array will be returned if the result set contains no rows.
    #
    # If the result set contains a lot of rows, this will create an array that requires a lot of
    # memory, so use with caution.
    #
    # The result set will be closed when the method returns.
    def all_array
      all_results(true)
    end

    # Similar to next_array, only it returns the result as a hash. The hash will have one key
    # for each column in the corresponding select statement. The key will be the upper case name of
    # the column or alias from the SQL statement.
    def next_hash
      next_row(false)
    end

    # Processes each row of the result set using hte provided block, passing one row as a time to
    # the block as a hash, eg:
    #
    #    obj.each_hash do |r|
    #      # process the row
    #    end
    #
    # The result set will be closed when the method returns.
    def each_hash(&blk)
      each_result false, &blk
    end

    # Consumes all the rows of the result set, and returns the result as an array of hashes.
    #
    # An empty array will be returned if the result set contains no rows.
    #
    # If the result set contains a lot of rows, this will create an array that requires a lot of
    # memory, so use with caution.
    #
    # The result set will be closed when the method returns.
    def all_hash
      all_results(false)
    end

    # Closes the result set if it exists, and also closes the SQL statement that created the result
    # set.
    # TODO - does it make sense to close the statement here too?
    def close_result_set
      if @result_set
        @result_set.close
        @result_set = nil
      end
      close_statement
    end

    private

    def row_as_array
      cols = @result_set.get_meta_data.get_column_count
      a = Array.new
      1.upto(cols) do |i|
        a.push retrieve_value(@result_set, i)
      end
      a
    end

    def row_as_hash
      mdata = @result_set.get_meta_data
      cols = mdata.get_column_count
      h = Hash.new
      1.upto(cols) do |i|
        h[mdata.get_column_name(i)] = retrieve_value(@result_set, i)
      end
      h
    end

    def all_results(array=true)
      raise SimpleOracleJDBC::NoResultSet unless @result_set
      results = Array.new
      begin
        while(r = @result_set.next) do
          if array
            results.push row_as_array
          else
            results.push row_as_hash
          end
        end
      ensure
        close_result_set
      end
      results
    end

    def each_result(as_array=true, &blk)
      raise SimpleOracleJDBC::NoResultSet unless @result_set
      begin
        while(r = @result_set.next)
          if as_array
            yield row_as_array
          else
            yield row_as_hash
          end
        end
      ensure
        close_result_set
      end
    end

    def next_row(as_array=true)
      raise SimpleOracleJDBC::NoResultSet unless @result_set
      r = @result_set.next
      if r
        if as_array
          row_as_array
        else
          row_as_hash
        end
      else
        close_result_set
        nil
      end
    end

  end
end
