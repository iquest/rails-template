# frozen_string_literal: true

# Seeds.truncate('users', cascade: true)
User.find_or_create_by(email: 'admin@iquest.cz') do |u|
  u.name = 'Admin iQuest'  
  u.role = 'admin'
  u.password = 'password'
end

