FactoryGirl.define do
  factory :news, class: 'New' do
    volunteer_id 0
    news_type { "Status" }
    content Faker::Lorem.sentence
    title Faker::Name.name
    self.private { false }
    group_id 0
    group_type { group_type }
    group_name { group_name }
    group_thumb_path { group_thumb_path }
    number_comments 0
    as_group { as_group }
    volunteer_name { volunteer_name }
    volunteer_thumb_path { volunteer_thumb_path }
  end
end
