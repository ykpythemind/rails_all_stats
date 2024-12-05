require 'bundler'
require 'open3'

def rails_version(revision:)
  lockfile, _, status = Open3.capture3("git show #{revision}:Gemfile.lock")
  if status.exitstatus == 0
    # rails gemが見つからないときもあるのでnilチェック必要
    spec = Bundler::LockfileParser.new(lockfile).specs.find { _1.name == "rails" }
    spec.version.to_s if spec
  else
    # Gemfile.lockがない。。。Gemfileから推測するしかないが一旦無視
    nil
  end
end

def call
  current_date = nil
  logs = []

  o, e = Open3.capture2("git log --pretty=format:'%h %cd' --date=format:'%Y/%m/%d' --reverse")
  o.each_line do |line|
    revision, date = line.split
    if current_date != date
      logs << { date:, revision: }
      current_date = date
    end
  end

  versions = {}
  logs.each do |log|
    version = rails_version(revision: log[:revision])
    next if version.nil?
    unless versions.has_key?(version)
      # gemfile.lockに初出したタイミングでそのバージョンに切り替わったと見なすこととする
      versions[version] = true
      s = "#{log[:date]} #{version}"
      s += " #{log[:revision]}" if ENV['INCLUDE_REVISION']
      puts s
    end
  end
end

rails_root_dir = ARGV[0]

if rails_root_dir
  Dir.chdir(rails_root_dir) do
    call
  end
else
  abort "Usage: ruby version-history.rb /path/to/rails_repository"
end
