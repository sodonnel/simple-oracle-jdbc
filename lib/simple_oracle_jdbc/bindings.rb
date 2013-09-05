module SimpleOracleJDBC
  module Binding

    include SimpleOracleJDBC::TypeMap

    # Provides a set of methods to map Ruby types to their JDBC equivalent and back again.


    RUBY_TO_JDBC_TYPES = {
      Date       => OracleTypes::DATE,
      Time       => OracleTypes::TIMESTAMP,
      String     => OracleTypes::VARCHAR,
   #   Clob       => OracleTypes::VARCHAR,
      Fixnum     => OracleTypes::INTEGER,
      Integer    => OracleTypes::INTEGER,
      Bignum     => OracleTypes::NUMERIC,
      Float      => OracleTypes::NUMERIC,
      :refcursor => OracleTypes::CURSOR,
      :raw       => OracleTypes::RAW
    }

    # Given a JDBC prepared call or prepared statement, a value and a bind index, the value
    # will be bound to JDBC statement.
    #
    # If value is a single value, ie not an array in is considered an IN parameter.
    #
    # If value is an array, then it should have either 2 or 3 elements.
    #
    # * 2 elements indictes the value is an IN parameter, element 0 indicates the type
    # of the bind variable, and element 1 is the value, eg:
    #
    #    [String, "Some_value"]
    #
    # * 3 elements indicates the value is an OUT or an IN OUT parameter (useful only when using
    # stored procedures), eg:
    #
    #    [String, "Some_value", :out]
    #    [:refcursor, nil, :out]
    #
    # When binding values, Ruby types are mapped to Java / JDBC types based on the type
    # of the passed in Ruby object. The mapping is as follows:
    #
    #    RUBY_TO_JDBC_TYPES = {
    #      Date       => OracleTypes::DATE,
    #      Time       => OracleTypes::TIMESTAMP,
    #      String     => OracleTypes::VARCHAR,
    #      Fixnum     => OracleTypes::INTEGER,
    #      Integer    => OracleTypes::INTEGER,
    #      Bignum     => OracleTypes::NUMERIC,
    #      Float      => OracleTypes::NUMERIC,
    #      :refcursor => OracleTypes::CURSOR,
    #      :raw       => OracleTypes::RAW
    #    }
    #
    # Note that to bind a ref_cursor, there is no natural Ruby class, so it can only be bound using
    # the array form for values.
    #
    # Also note that in this version, it is not possible to bind a ref_cursor into a procedure - it can
    # only be retrieved.
    def bind_value(obj, v, i)
      type  = v.class
      value = v
      if v.is_a? Array
        # class is being overriden from the input
        type = v[0]
        value = v[1]

        if v.length == 3
          bind_out_parameter(obj, i, type, value)
        end
      end

      if type == Date
        bind_date(obj, value, i)
      elsif type == Time
        bind_time(obj, value, i)
      elsif type == String
        bind_string(obj, value, i)
      elsif type == Fixnum or type == Integer
        bind_int(obj, value, i)
      elsif type == Float
        bind_number(obj, value, i)
      elsif type == :refcursor
        bind_refcursor(obj, value, i)
      elsif type == :raw
        bind_raw(obj, value, i)
      elsif type == SimpleOracleJDBC::OraArray
        value.bind_to_call(@connection, obj, i)
      else
        raise UnknownBindType, type.to_s
      end
    end

    # Given a open JDBC result set and a column index, the value is retrieved
    # and mapped into a Ruby type.
    #
    # The columns are indexed from 1 in the array.
    #
    # If the retrieved value is null, nil is returned.
    def retrieve_value(obj, i)
      case obj.get_meta_data.get_column_type_name(i)
      when 'NUMBER'
        retrieve_number(obj, i)
      when 'INTEGER'
        retrieve_int(obj, i)
      when 'DATE'
        retrieve_time(obj, i)
      when 'TIMESTAMP'
        retrieve_time(obj, i)
      when 'CHAR', 'VARCHAR2', 'CLOB'
        retrieve_string(obj, i)
      when 'RAW'
        retrieve_raw(obj, i)
      else
        raise UnknownSQLType, obj.get_meta_data.get_column_type_name(i)
      end
    end

    # :nodoc:
    def bind_out_parameter(obj, index, type, value)
      if type == SimpleOracleJDBC::OraArray
        value.register_as_out_parameter(@connection, obj, index)
      else
        internal_type = RUBY_TO_JDBC_TYPES[type] || OracleTypes::VARCHAR
        obj.register_out_parameter(index, internal_type)
      end
    end

    def bind_date(obj, v, i)
      if v
        # %Q is micro seconds since epoch. Divide by 1000 to get milli-sec
        obj.set_date(i, ruby_date_as_jdbc_date(v))
      else
        obj.set_null(i, OracleTypes::DATE)
      end
    end

    def bind_time(obj, v, i)
      if v
        # Need to use an Oracle TIMESTAMP - dates don't allow a time to be specified
        # for some reason, even though a date in Oracle contains a time.
        obj.setTIMESTAMP(i, ruby_time_as_jdbc_timestamp(v))
      else
        obj.set_null(i, OracleTypes::TIMESTAMP)
      end
    end

    def bind_string(obj, v, i)
      if v
        obj.set_string(i, v)
      else
        obj.set_null(i, OracleTypes::VARCHAR)
      end
    end

    def bind_int(obj, v, i)
      if v
        obj.set_int(i, v)
      else
        obj.set_null(i, OracleTypes::INTEGER)
      end
    end

    def bind_number(obj, v, i)
      if v
        obj.set_number(i, ruby_number_as_jdbc_number(v))
      else
        obj.set_null(i, OracleTypes::NUMBER)
      end
    end

    def bind_refcursor(obj, v, i)
      if v
        raise "not implemented"
      end
    end

    def bind_raw(obj, v, i)
      if v
        obj.set_raw(i, ruby_raw_string_as_jdbc_raw(v))
      else
        obj.set_null(i, OracleTypes::RAW)
      end
    end

    def retrieve_date(obj, i)
      jdate = obj.get_date(i)
      java_date_as_date(jdate)
    end

    def retrieve_time(obj, i)
      jdate = obj.get_timestamp(i)
      java_date_as_time(jdate)
    end

    def retrieve_string(obj, i)
      obj.get_string(i)
    end

    def retrieve_int(obj, i)
      v = obj.get_int(i)
      if obj.was_null
        v = nil
      end
      java_integer_as_integer(v)
    end

    def retrieve_number(obj, i)
      v = obj.get_number(i)
      java_number_as_float(v)
    end

    def retrieve_refcursor(obj, i)
      rset = obj.get_object(i)
      # Dummy connection passed as it is never needed?
      results = Sql.new(nil)
      results.result_set = rset
      results
    end

    def retrieve_raw(obj, i)
      v = obj.get_raw(i)
      oracle_raw_as_string(v)
    end

  end
end
