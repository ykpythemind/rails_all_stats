require 'open3'
require 'pathname'

def red(t) = STDOUT.isatty ? "\e[31m#{t}\e[0m" : t
def bold(t) = STDOUT.isatty ? "\e[1m#{t}\e[0m" : t

def run(command, path)
  stdout, stderr, status =
    Open3.capture3(
      ENV.to_h,
      [command].compact.join(" "),
      chdir: path,
    )

  if status.exitstatus == 0
    puts stdout
  else
    puts red("Command failed with status #{status.exitstatus}:\n\n#{stderr}")
  end
end

def with_tmp_file(rails_root, src)
  dst = Pathname.new(rails_root).join("tmp").join(src)
  FileUtils.cp(Pathname.new(__FILE__).dirname.join(src), Pathname.new(rails_root).join("tmp"))

  yield
ensure
  dst.delete if dst.exist?
end

rails_root = ARGV[0]
if rails_root.nil?
  puts "Usage: ruby rails_all_stats.rb path/to/rails_root"
  abort
end

[
  { strategy: :rails_runner, script: "print_rails_config.rb" },
  { strategy: :rails_runner, script: "hot_routes.rb" },
  { strategy: :script, script: "hot_class.rb" },
  { strategy: :script, script: "table_count.rb" },
].each do |a|
  puts bold("#{a[:script]}")
  puts

  case a[:strategy]
  when :rails_runner
    with_tmp_file(rails_root, a[:script]) do
      rails_command = "bin/rails runner"
      rails_command = ENV["RAILS_COMMAND"] if ENV["RAILS_COMMAND"]
      run("#{rails_command} r tmp/#{a[:script]}", rails_root)
    end
  when :script
    run("ruby #{a[:script]} #{rails_root}", Pathname.new(__FILE__).dirname)
  end

  puts
  puts
end
