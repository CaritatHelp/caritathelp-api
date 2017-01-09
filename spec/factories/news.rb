FactoryGirl.define do
  factory :new, class: 'New' do
    news_type "Status"
    content Faker::Lorem.sentence
    title Faker::Name.name
    self.private { false }
    number_comments 0

    group_id { group_id }
    group_type { group_type }
    group_name { group_name }
    group_thumb_path { group_thumb_path }
    as_group { as_group }
    volunteer_id { volunteer_id }
    volunteer_name { volunteer_name }
    volunteer_thumb_path { volunteer_thumb_path }
  end
end
