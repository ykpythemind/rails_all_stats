require 'bundler'
require 'open3'
require 'tmpdir'

CURRENT_DIR = Dir.pwd

def with_git_worktree(git_root, revision)
  Dir.mktmpdir do |dir|
    Dir.chdir(git_root) do
      _, e, s = Open3.capture3("git worktree add #{dir} #{revision}")
      raise "Command failed: #{e}" if s.exitstatus != 0
      yield dir
    ensure
      # system("git worktree remove #{dir}")
    end
  end
end

def stats_at(git_root:, git_revision:)
  loc, testloc = nil
  with_git_worktree(git_root, git_revision) do |worktree_dir|
    Dir.chdir(CURRENT_DIR) do
      o, e, s = Open3.capture3("bundle exec rake stats[#{worktree_dir}]") # jsonオプションがあるけど効いてない
      if s.exitstatus != 0
        raise "Command failed: #{e}"
      end

      # extract Code LOC
      loc = o.match(/Code LOC: (\d+)/)[1]
      testloc = o.match(/Test LOC: (\d+)/)[1]
    end
  end

  [loc, testloc]
end

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

      loc, testloc = stats_at(git_root: Dir.pwd, git_revision: log[:revision])

      s+= " #{loc} #{testloc}"

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
