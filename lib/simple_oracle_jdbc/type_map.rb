module SimpleOracleJDBC
  module TypeMap

    def java_date_as_date(v)
      if v
        Date.new(v.get_year+1900, v.get_month+1, v.get_date)
      else
        nil
      end
    end

    def java_date_as_time(v)
      if v
        Time.at(v.get_time.to_f / 1000)
      else
        nil
      end
    end

    def java_number_as_float(v)
      if v
        v.double_value
      else
        nil
      end
    end

    def java_integer_as_integer(v)
      # JRuby automatically converts INT to INT
      v
    end

    def java_string_as_string(v)
      # JRubyt automatically converts to a Ruby string
      v
    end

    def oracle_raw_as_string(v)
      if v
        v.string_value
      else
        nil
      end
    end

    def ruby_date_as_jdbc_date(v)
      if v
        jdbc_date = Java::JavaSql::Date.new(v.strftime("%s").to_f * 1000)
      else
        nil
      end
    end

    def ruby_time_as_jdbc_timestamp(v)
      if v
        TIMESTAMP.new(Java::JavaSql::Timestamp.new(v.to_f * 1000))
      else
        nil
      end
    end

    def ruby_any_date_as_jdbc_date(v)
      if v
        if v.is_a? Date
          ruby_date_as_jdbc_date(v)
        elsif v.is_a? Time
          ruby_time_as_jdbc_timestamp(v)
        else
          raise "#{v.class}: unimplemented Ruby date type for arrays. Use Date or Time"
        end
      else
        nil
      end
    end

    def ruby_number_as_jdbc_number(v)
      if v
        # Avoid warning that appeared in JRuby 1.7.3. There are many signatures of
        # Java::OracleSql::NUMBER and it has to pick one. This causes a warning. This
        # technique works around the warning and forces it to the the signiture with a
        # double input - see https://github.com/jruby/jruby/wiki/CallingJavaFromJRuby
        # under the Constructors section.
        construct = Java::OracleSql::NUMBER.java_class.constructor(Java::double)
        construct.new_instance(v)
      else
        nil
      end
    end

    def ruby_raw_string_as_jdbc_raw(v)
      if v
        Java::OracleSql::RAW.new(v)
      else
        v
      end
    end

  end
end
