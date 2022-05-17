# frozen_string_literal: true

module RedAmber
  # data frame class
  #   @table   : holds Arrow::Table object
  class DataFrame
    # mix-in
    include DataFrameSelectable
    include DataFrameDisplayable

    def initialize(*args)
      # DataFrame.new, DataFrame.new([]), DataFrame.new({}), DataFrame.new(nil)
      #   returns empty DataFrame
      @table = Arrow::Table.new({}, [])
      # bug in gobject-introspection: ruby-gnome/ruby-gnome#1472
      #  [Arrow::Table] == [nil] shows ArgumentError
      #  temporary use yoda condition to workaround
      return if args.empty? || args == [[]] || args == [{}] || [nil] == args

      if args.size > 1
        @table = Arrow::Table.new(*args)
      else
        arg = args[0]
        @table =
          case arg
          when Arrow::Table then arg
          when DataFrame then arg.table
          when Rover::DataFrame then Arrow::Table.new(arg.to_h)
          when Hash then Arrow::Table.new(arg)
          else
            raise DataFrameTypeError, "invalid argument: #{arg}"
          end
      end
    end

    def self.load(path, options = {})
      DataFrame.new(Arrow::Table.load(path, options))
    end

    attr_reader :table

    def save(output, options = {})
      @table.save(output, options)
    end

    # Properties ===
    def n_rows
      @table.n_rows
    end
    alias_method :nrow, :n_rows
    alias_method :size, :n_rows
    alias_method :length, :n_rows

    def n_columns
      @table.n_columns
    end
    alias_method :ncol, :n_columns
    alias_method :width, :n_columns

    def shape
      [n_rows, n_columns]
    end

    def column_names
      @table.columns.map { |column| column.name.to_sym }
    end
    alias_method :keys, :column_names
    alias_method :header, :column_names

    def key?(key)
      column_names.include?(key.to_sym)
    end
    alias_method :has_key?, :key?

    def key_index(key)
      column_names.find_index(key.to_sym)
    end
    alias_method :find_index, :key_index
    alias_method :index, :key_index

    def types
      @table.columns.map do |column|
        column.data_type.to_s.to_sym
      end
    end

    def data_types
      @table.columns.map do |column|
        column.data_type.class
      end
    end

    def vectors
      @table.columns.map do |column|
        Vector.new(column.data)
      end
    end

    def to_h
      @table.columns.each_with_object({}) do |column, result|
        result[column.name.to_sym] = column.entries
      end
    end

    def to_a
      # output an array of row-oriented data without header
      # if you need column-oriented array, use `.to_h.to_a`
      @table.raw_records
    end
    alias_method :raw_records, :to_a

    def schema
      keys.zip(types).to_h
    end

    def ==(other)
      other.is_a?(DataFrame) && @table == other.table
    end

    def empty?
      @table.columns.empty?
    end

    def to_rover
      Rover::DataFrame.new(to_h)
    end

    # def to_parquet() end
  end
end
