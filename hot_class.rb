require 'bundler/setup'
require 'prism'
require 'pathname'

class ClassVisitor < Prism::Visitor
  def initialize
    @length = 0
    @map = {}
    @current_class = nil
  end

  attr_reader :map

  def visit_class_node(node)
    k = node.constant_path.full_name_parts.map(&:to_s).join("::")
    @current_class = k
    @map[@current_class] ||= 0
    @map[@current_class] += node.slice.split("\n").size
    super
    @current_class = nil
  end

  def result = map
end

rails_root = ARGV[0]
if rails_root.nil?
  puts "Usage: ruby hot_class.rb path/to/rails_root"
  abort
end

visitor = ClassVisitor.new
Dir.glob(Pathname.new(rails_root).join("app/models/**/*.rb")).each do |file|
  parse_result = Prism.parse_file(file)
  parse_result.value.accept(visitor)
end

rows = visitor.result.map { |k, v| [k, v] }.sort_by { _2 }.reverse
rows = rows.take(10) unless ENV["VERBOSE"] # top 10

longest = rows.max_by { _1[0].length }[0].length + 1
pad = 10
rows.unshift(["-"*longest, "-"*pad, "-"*pad])
rows.unshift(["class", "length"])

rows.each do |r|
  puts "#{r[0].strip.ljust(longest)} | #{r[1].to_s.ljust(pad)}"
end
