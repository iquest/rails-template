# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require "csv"
require_relative "seeds/lib/utils"

env = Rails.env

glob = "*.rb"
only = ENV['ONLY'].presence
glob = "*{#{only}}.*rb" if glob
filenames = Dir.glob("#{Rails.root.join('db', 'seeds')}/#{glob}").sort
envdirname = Rails.root.join("db", "seeds", env.to_s)
filenames += Dir.glob("#{envdirname}/#{glob}").sort if Dir.exist?(envdirname)

puts "Seeding #{env} environment"
filenames.each do |filename|
  puts "Seeding #{File.basename(filename)}"
  require filename
end
