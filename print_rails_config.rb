# 使い方
# - {Rails.root}/tmp/print_rails_config.rb に配置
# - bin/rails r tmp/print_rails_config.rb
#
# 既知の問題点
# - Rails.envによるデフォルトの差異は見えない
# - eager_load_pathsなどの設定を見たいけど、デフォルト値がapplication.rbに書かれる方式なので取得が困難。実施していない
# - 設定の値がnil && デフォルト値がnilでない 場合に、未指定（デフォルト値が使われる）のか、明示的にnilを指定されたのか区別できていない

class Proc
  def as_json = "(proc)"
end

TARGET_CONFIGS = [
  "action_view.form_with_generates_remote_forms",
  "action_view.button_to_generates_button_tag",

  "active_record.automatic_scope_inversing",
  "active_record.run_commit_callbacks_on_first_saved_instances_in_transaction",
  "active_record.belongs_to_required_by_default",
  "active_record.strict_loading_mode",
  "active_record.strict_loading_by_default",
  "active_record.encryption.hash_digest_class",
  "active_record.protocol_adapters",

  "action_controller.include_all_helpers",
  "active_storage.variant_processor",
  "action_dispatch.use_authenticated_cookie_encryption",
  "active_support.use_authenticated_message_encryption",
  "active_support.to_time_preserves_timezone",
  "yjit",
  "log_tags",
]

def extract_config(conf)
  h = {}
  TARGET_CONFIGS.each do |config_name|
    next if config_name.start_with?("active_record") && defined?(Mongoid) # mongoidを使っているので存在しないのだ...!

    begin
      value = config_name.split(".").reduce(conf) { _1.send(_2) }
    rescue NoMethodError => _e # いまのバージョンに存在しないコンフィグ (例: yjit)
        value = "n/a"
    end

    h[config_name] = value
  end
  h
end

seg = Gem::Version.new(Rails.version).segments
local_short_ver = "#{seg[0]}.#{seg[1]}"

if ARGV[0] == "rails_default"
  j = extract_config(Rails::Application::Configuration.new(Rails.root).tap { _1.load_defaults(local_short_ver) })
  File.write("tmp/rails_default.json", j.to_json)
else
  run = true
end

def f(v) = v.is_a?(String) ? v : v.inspect

if run
  # Rails.application.configが意図せず汚染されるのでrails_default取得を別プロセスで実行せざるを得ない。なんで〜
  system("bin/rails r tmp/print_rails_config.rb rails_default")

  default_configs = JSON.parse(Rails.root.join("tmp/rails_default.json").read)
  local_configs = extract_config(Rails.application.config).as_json

  rows = local_configs.map do |config_name, _|
    local_value = local_configs[config_name]
    default_value = default_configs[config_name]
    title = local_value == default_value ? config_name : config_name + " ⚠️"
    [ title, f(local_value), f(default_value) ]
  end

  longest = rows.max_by { _1[0].length }[0].length + 1
  pad = 23
  rows.unshift(["-"*longest, "-"*pad, "-"*pad])
  rows.unshift(["config", "local(#{Rails.version})", "default(#{local_short_ver})"])

  puts
  rows.each do |r|
    puts "#{r[0].ljust(longest)} | #{r[1].ljust(pad).truncate(pad)} | #{r[2].ljust(pad)}"
  end
  puts
end
