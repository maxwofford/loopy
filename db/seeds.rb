admin = User.find_or_create_by!(hca_id: "ident!ePlfv4") do |u|
  u.email = "max@hackclub.com"
end

puts "Admin user: #{admin.email} (#{admin.hca_id})"
