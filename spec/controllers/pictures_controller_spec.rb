require 'rails_helper'

ex_base64 = "iVBORw0KGgoAAAANSUhEUgAAAA0AAAANCAYAAABy6+R8AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJ
bWFnZVJlYWR5ccllPAAAAyJpVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdp
bj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6
eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYwIDYxLjEz
NDc3NywgMjAxMC8wMi8xMi0xNzozMjowMCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJo
dHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlw
dGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAv
IiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RS
ZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpD
cmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIENTNSBNYWNpbnRvc2giIHhtcE1NOkluc3RhbmNl
SUQ9InhtcC5paWQ6RDU0NDVDNjI0MUE4MTFFMTk3OURDRDgxOTNEMUU3NTYiIHhtcE1NOkRvY3Vt
ZW50SUQ9InhtcC5kaWQ6MjlFQzUyODQ0MUIyMTFFMTk3OURDRDgxOTNEMUU3NTYiPiA8eG1wTU06
RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDpENTQ0NUM2MDQxQTgxMUUxOTc5
RENEODE5M0QxRTc1NiIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDpENTQ0NUM2MTQxQTgxMUUx
OTc5RENEODE5M0QxRTc1NiIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1w
bWV0YT4gPD94cGFja2V0IGVuZD0iciI/PuhQNCgAAABuSURBVHjaYmCAgv///zcA8fv/CABiNzDg
AkDJ8/9xg/PYNDQgmRyAJB6AZHMDuiaYRAAWAwNgBqJLgAEep2PIMzGQAUCaPsCcgs15UOYHqgSE
AJYgf4/GL8DlYayRC9KAM77wASSX0Ffje4AAAwDkqAbz4euqrgAAAABJRU5ErkJggg=="

RSpec.describe PicturesController, type: :controller do
  include Devise::Test::ControllerHelpers

  describe 'create' do
  	volunteer = FactoryGirl.create(:volunteer)
  	assoc = FactoryGirl.create(:assoc)
  	event = FactoryGirl.create(:event, assoc_id: assoc.id)
  	FactoryGirl.create(:event_volunteer, volunteer_id: volunteer.id, event_id: event.id, rights: "host")

  	it "successfuly upload an image to the volunteer profile" do
  		log volunteer
  		expect { post :create, { file: ex_base64, filename: Faker::Name.first_name + ".png", original_filename: "loupe.png" } }.to change { Picture.count }.by(1)
  		expect_success response
  	end

  	it "successfuly upload an image to an event" do
  		log volunteer
  		expect { post :create, { file: ex_base64, filename: Faker::Name.first_name + ".png", original_filename: "loupe.png", event_id: event.id } }.to change { Picture.count }.by(1)
  		expect_success response
  	end

  	it "fails to upload image to an association because of rights issues" do
  		log volunteer
  		expect { post :create, { file: ex_base64, filename: Faker::Name.first_name + ".png", original_filename: "loupe.png", assoc_id: assoc.id } }.to change { Picture.count }.by(0)
  		expect_failure response
  	end
  end
end
