routes = Rails.application.routes.routes
paths = routes.map { _1.path.spec.to_s }

paths.map! { _1.delete_suffix("(.:format)") }.uniq!

a = paths.group_by do |path|
  s = path.split("/")

  if s[3]
    "/#{s[1]}/#{s[2]}/*"
  elsif s[2] || s[1]
    "/#{s[1]}/*"
  else
    ""
  end
end

b = a.select { |k,v| v.count > 2 }.map { |k, v| [k, v.count] }
b.sort! { _1[1] <=> _2[1] }.reverse!

longest = b.max_by { _1[0].length }[0].length

puts "#{"path".ljust(longest)} | count"
puts "#{"-" * longest} | -----"
b.each do |v|
  puts "#{v[0].ljust(longest)} | #{v[1]}"
end
