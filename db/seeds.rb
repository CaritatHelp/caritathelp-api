load File.join(Rails.root, 'db', 'seeds', 'helper.rb')
(Dir[File.join(Rails.root, 'db', 'seeds', '*.rb')] - ['helper.rb']).sort.each { |seed| load seed }
