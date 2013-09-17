module SimpleOracleJDBC

  class OraArray
    include TypeMap

    attr_reader :ora_type

    # This must be initialized with the name of the Oracle array type as defined
    # on the database, ie the t_name is table of varchar2(10);
    #
    # Values must be an array of Ruby objects, or nil. The values in the array
    # will be cast into the appropriate Oracle type depending on the definition
    # of the array defined in Oracle.
    def initialize(ora_type, values)
      @ora_type   = ora_type.upcase
      self.values = values
      @descriptor = nil
    end

    # Values must be a Ruby array of objects or nil.
    #
    # While the values can be set in upon object initialization, this method
    # allows them to be changed. The one advantage is that it allows the
    # array descriptor to be reused across many database calls. As this must
    # be queried from the database, it requires 1 database round trip for each new object,
    # but is cached inside the object once it is initialized.
    def values=(value_array)
      if value_array and !value_array.is_a? Array
        raise "The values must be a Ruby array, not #{value_array.class}"
      end
      @values = value_array || Array.new
    end

    # Given a database connection, a prepared statement and a bind index,
    # this method will bind the array of values (set at object initialization time
    # or by the values= method) to the statement.
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
      elsif @values.first.is_a? Array or @values.first.nil?
        # If the value is an array, assume we are dealing with an array
        # of records. Also need the nil check as we could be binding
        # an empty array or a return value.
        jarray = create_struct_array(conn, base_type,@values)
      else
        raise "#{base_type}: Unimplemented Array Type"
      end
      ora_array = ARRAY.new(@descriptor, conn, jarray)
      stmt.set_object(index, ora_array)
    end


    # Given a database connection, a prepared statement and a bind index,
    # register the bind at that index as an out or inout parameter.
    def register_as_out_parameter(conn, stmt, index)
      set_descriptor(conn)
      stmt.register_out_parameter(index, OracleTypes::ARRAY, @ora_type)
    end

    # After executing a statement, retrieve the resultant array from Oracle
    # returning a Ruby array of Ruby objects.
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
        retrieve_oracle_record(conn, base_type, ora_array)
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

    def retrieve_oracle_record(conn, type, ora_array)
      ora_record = OraRecord.new(type,nil)
      ora_array.get_array.to_a.map{|r| ora_record.convert_struct_to_ruby(conn, r) }
    end

    # Converts an array of arrays into their intended Oracle
    # record type
    def create_struct_array(conn, type, values)
      ora_record = OraRecord.new(type, nil)
      array_of_structs = Array.new
      values.each do |v|
        array_of_structs.push ora_record.convert_to_oracle_struct(conn, v)
      end
      array_of_structs.to_java
    end


  end

end

