allowed_users = {
  "ident!ZEOfPe" => "nora@hackclub.com",
  "ident!ePlfv4" => "max@hackclub.com"
}

allowed_users.each do |hca_id, email|
  user = User.find_or_create_by!(hca_id: hca_id) do |u|
    u.email = email
  end
  user.update!(can_create_keys: true)
  puts "Allowed user: #{user.email} (#{user.hca_id})"
end
