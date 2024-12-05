require 'bundler/setup'
require 'prism'
require 'pathname'

class Visitor < Prism::Visitor
  attr_reader :count

  def initialize
    super()
    @count = 0
  end

  def visit_call_node(node)
    super
    if node.name == :create_table
      @count += 1
    end
  end
end

rails_root = ARGV[0]
if rails_root.nil?
  puts "Usage: ruby table_count.rb path/to/rails_root"
  abort
end

parse_result = Prism.parse_file(Pathname.new(rails_root).join('db/schema.rb').to_s)
visitor = Visitor.new
parse_result.value.accept(visitor)

puts visitor.count
