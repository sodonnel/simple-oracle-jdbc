module SimpleOracleJDBC

  class OraArray
    include TypeMap

    attr_reader :ora_type

    # This must be initialized with the name
    # of the Oracle array type, ie the t_name
    # is table of varchar2(10) etc.
    def initialize(ora_type, values)
      @ora_type   = ora_type.upcase
      self.values = values
      @descriptor = nil
    end

    # Set or reset the values stored in this Object. This allows the same
    # object to be reused many times, saving calls to the database to
    # describe the array type.
    def values=(value_array)
      if value_array and !value_array.is_a? Array
        raise "The values must be a Ruby array, not #{value_array.class}"
      end
      @values = value_array || Array.new
    end

    def bind_to_call(conn, stmt, index)
      # First thing that is need is a descriptor for the given type
      set_descriptor(conn)
      base_type = @descriptor.get_base_name

      jarray = nil
      if base_type == 'VARCHAR' or base_type == 'CHAR'
        jarray = @values.to_java
      elsif base_type == 'RAW'
        jarray = @values.map{|i| ruby_raw_string_as_jdbc_raw(i) }.to_java
      elsif base_type == 'NUMBER' or base_type == 'INTEGER'
        jarray = @values.map{|i| ruby_number_as_jdbc_number(i) }.to_java
      elsif base_type == 'DATE' or base_type == 'TIMESTAMP'
        jarray = @values.map{|i| ruby_any_date_as_jdbc_date(i) }.to_java
      else
        raise "#{base_type}: Unimplemented Array Type"
      end
      ora_array = ARRAY.new(@descriptor, conn, jarray)
      stmt.set_object(index, ora_array)
    end

    def register_as_out_parameter(conn, stmt, index)
      set_descriptor(conn)
      stmt.register_out_parameter(index, OracleTypes::ARRAY, @ora_type)
    end

    def retrieve_out_value(conn, stmt, index)
      set_descriptor(conn)
      ora_array = stmt.get_array(index)
      base_type = ora_array.get_base_type_name
      if base_type == 'VARCHAR' or base_type == 'CHAR'
        retrieve_as_string(ora_array)
      elsif base_type == 'RAW'
        retrieve_as_raw(ora_array)
      elsif base_type == 'NUMBER' or base_type == 'INTEGER'
        retrieve_as_number(ora_array)
      elsif base_type == 'DATE' or base_type == 'TIMESTAMP'
        retrieve_as_date(ora_array)
      else
        raise "#{base_type}: Unimplemented Array Type"
      end
    end

    private

    def set_descriptor(conn)
      @descriptor ||= ArrayDescriptor.createDescriptor(@ora_type, conn);
    end

    def retrieve_as_string(ora_array)
      ora_array.get_array.to_a
    end

    def retrieve_as_number(ora_array)
      ora_array.get_array.to_a.map{|v| java_number_as_float(v) }
    end

    def retrieve_as_raw(ora_array)
      ora_array.get_oracle_array.to_a.map{|v| oracle_raw_as_string(v) }
    end

    # Always returns dates are Ruby Time objects
    def retrieve_as_date(ora_array)
      ora_array.get_array.to_a.map{|v| java_date_as_time(v) }
    end

  end

end

