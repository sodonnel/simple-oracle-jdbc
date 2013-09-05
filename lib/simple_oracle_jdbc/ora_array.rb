module SimpleOracleJDBC

  class OraArray
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
      internal_type = @descriptor.get_base_name

      jarray = nil
      if internal_type == 'DATE' or internal_type == 'TIMESTAMP'
        # need to convert ruby dates / times to Java
        jarray = @values.map{|i| date_to_java(i) }.to_java
      else
        # other types seems to be handled OK by default
        jarray = @values.to_java
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
      elsif base_type == 'NUMBER'
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
      ora_array.get_array.to_a.map{|v| v ? v.double_value : nil }
    end

    def retrieve_as_raw(ora_array)
      ora_array.get_oracle_array.to_a.map{|v| v ? v.string_value : nil }
    end

    # Always returns dates are Ruby Time objects
    def retrieve_as_date(ora_array)
      ora_array.get_array.to_a.map{|v| v ? Time.at(v.get_time.to_f / 1000) : nil }
    end

    def date_to_java(date)
      if date
        if date.is_a? Date
           Java::JavaSql::Date.new(date.strftime("%s").to_f * 1000)
        elsif date.is_a? Time
          TIMESTAMP.new(Java::JavaSql::Timestamp.new(date.to_f * 1000))
        else
          raise "#{date.class}: unimplemented Ruby date type for arrays. Use Date or Time"
        end
      else
        nil
      end
    end

  end

end

