# frozen_string_literal: true

module Seeds
  def self.root
    Rails.root.join('db/seeds')
  end

  def self.logger
    Rails.logger
  end

  def self.data(filename)
    data_dir = root.join('data')
    file_path = data_dir.join(filename)
    case ext = File.extname(filename)
    when ".yml"
      yaml_file(file_path)
    when ".csv"
      csv_file(file_path)
    else
      puts "Extension #{ext} not supported"
    end
  end

  def self.file(filename, &block)
    return unless filename

    files_dir = root.join("files")
    file_path = files_dir.join(filename)
    unless File.exist?(file_path)
      Seeds.logger.debug "File #{file_path} not found"
      return
    end

    return File.open(file_path) unless block_given?

    File.open(file_path, &block)
  end

  def self.dir(dir, glob = "*")
    return unless dir

    basedir = root.join(dir)
    return unless Dir.exist?(basedir)

    file_paths = Dir.glob("#{basedir}/#{glob}").sort

    if block_given?
      file_paths.each do |file_path|
        yield file_path
      end
    else
      file_paths
    end
  end

  def self.yaml(str)
    YAML.safe_load(str, symbolize_names: true)
  end

  def self.yaml_file(file_path)
    yaml(File.read(file_path))
  end

  def self.csv(str)
    CSV.parse(str, headers: true)
  end

  def self.csv_file(file_path)
    csv(File.read(file_path))
  end

  def self.truncate(*tables, cascade: false)
    tables.each do |table|
      query = "TRUNCATE TABLE #{table}"
      query = "#{query} CASCADE" if cascade
      puts query
      ActiveRecord::Base.connection.execute(query)
      reset_sequence(table)
    end
  end

  def self.transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end

  def self.import(filename)
    print "Import #{filename}"
    transaction do
      data(filename).each do |row|
        print "."
        yield row.to_h
      end
      print "DONE\n"
    end
  rescue StandardError => e
    print "FAILED\n"
    raise e
  end

  def self.reset_sequence(table)
    last_id = ActiveRecord::Base.connection.select_value("SELECT MAX(id) FROM #{table}")
    last_id ||= 0

    name = "#{table}_id_seq"
    query = "ALTER SEQUENCE #{name} RESTART WITH #{last_id + 1}"
    puts query
    ActiveRecord::Base.connection.execute(query)
  end
end
