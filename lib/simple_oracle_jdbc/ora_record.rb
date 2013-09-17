module SimpleOracleJDBC

  class OraRecord
    include TypeMap

    attr_reader :ora_type

    # This must be initialized with the name of the Oracle record type as defined
    # on the database, ie something like:
    #
    #    create or replace type t_record as object (
    #    p_varchar varchar2(10),
    #    p_integer integer
    #    );
    #
    # Values must be an array of Ruby objects, or nil. The values in the array
    # will be cast into the appropriate Oracle type depending on the definition
    # of the record defined in Oracle.
    def initialize(ora_type, values)
      @ora_type   = ora_type.upcase
      self.values = values
      @descriptor = nil
      @type_attributes = nil
    end

    # Values must be a Ruby array of objects or nil.
    #
    # While the values can be set in upon object initialization, this method
    # allows them to be changed. The one advantage is that it allows the
    # object descriptor to be reused across many database calls. As this must
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
      set_descriptor(conn)

      # Avoid binding an empty record for OUT parameters
      if @values.length == 0
        return
      end

      ora_array = convert_to_oracle_struct(conn, @values)
      stmt.set_object(index, ora_array)
    end

    # Given a ruby array, convert it into the Oracle STRUCT required
    # when binding it to a procedure call
    def convert_to_oracle_struct(conn, input)
      set_descriptor(conn)

      if @type_attributes.length != input.length
        raise "Not enough values (#{input.length}) for Oracle record (#{@type_attributes.length})"
      end

      temp_array = Array.new
      @type_attributes.each_with_index do |t, i|
        if t == 'VARCHAR' or t == 'CHAR'
          temp_array.push input[i]
        elsif t == 'RAW'
          temp_array.push ruby_raw_string_as_jdbc_raw(input[i])
        elsif t == 'NUMBER' or t == 'INTEGER'
          temp_array.push ruby_number_as_jdbc_number(input[i])
        elsif t == 'DATE' or t == 'TIMESTAMP'
          temp_array.push ruby_any_date_as_jdbc_date(input[i])
        else
          raise "#{base_type}: Unimplemented Record Type"
        end
      end
      ora_array = STRUCT.new(@descriptor, conn, temp_array.to_java)
    end

    # Given a database connection, a prepared statement and a bind index,
    # register the bind at that index as an out or inout parameter.
    def register_as_out_parameter(conn, stmt, index)
      set_descriptor(conn)
      stmt.register_out_parameter(index, OracleTypes::STRUCT, @ora_type)
    end

    # After executing a statement, retrieve the resultant array from Oracle
    # returning a Ruby array of Ruby objects.
    def retrieve_out_value(conn, stmt, index)
      set_descriptor(conn)
      convert_struct_to_ruby(conn, stmt.get_struct(index))
    end

    def convert_struct_to_ruby(conn, struct)
      set_descriptor(conn)
      final_array = Array.new

      ora_array = struct.get_attributes.to_a
      ora_array.each_with_index do |v,i|
        base_type = @type_attributes[i]
        if base_type == 'VARCHAR' or base_type == 'CHAR'
          final_array.push v
        elsif base_type == 'RAW'
          # RAW is a bit different as the default returned type is a byte array
          # By extracting the results as 'oracle_attributes' you get a to_string
          # method on the RAW type to turn it into a hex string.
          temp_array = struct.get_oracle_attributes.to_a
          final_array.push oracle_raw_as_string(temp_array[i])
        elsif base_type == 'NUMBER' or base_type == 'INTEGER'
          final_array.push java_number_as_float(v)
        elsif base_type == 'DATE' or base_type == 'TIMESTAMP'
          final_array.push java_date_as_time(v)
        else
          raise "#{base_type}: Unimplemented Record Type"
        end
      end
      final_array
    end

    private

    def set_descriptor(conn)
      @descriptor ||= StructDescriptor.createDescriptor(@ora_type, conn);
      set_type_attributes
    end

    def set_type_attributes
      unless @type_attributes
        @type_attributes = []
        meta = @descriptor.get_meta_data
        1.upto(meta.get_column_count) do |i|
          @type_attributes.push(meta.get_column_type_name(i))
        end
      end
    end

  end
end
