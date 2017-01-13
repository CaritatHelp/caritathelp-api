FactoryGirl.define do
  factory :news, class: 'New' do
    news_type "Status"
    content Faker::Lorem.sentence
    title Faker::Name.name
    self.private { false }
    number_comments 0

    group_id { group_id }
    group_type { group_type }
    as_group { as_group }
    volunteer_id { volunteer_id }
  end
end
