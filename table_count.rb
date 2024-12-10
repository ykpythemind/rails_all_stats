require 'bundler/setup'

rails_root = ARGV[0]
if rails_root.nil?
  puts "Usage: ruby table_count.rb path/to/rails_root"
  abort
end

Dir.chdir(rails_root) do
  puts `grep create_table db/schema.rb | wc -l`.strip
end
