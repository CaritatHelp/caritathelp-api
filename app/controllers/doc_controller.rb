class DocController < ApplicationController
  def index
    render :json => create_response(t("doc.response"), 404, t("doc.url"))
  end

  def errors
#     render :text => "token:
#     wrong: 'Wrong token'

#   assocs:
#     failure:
#       name:
#         unavailable: 'Unavailable name'
#         invalid: 'Invalid name'

#       update: 'Could not update assoc'
#       id: 'Unknown assoc id'
#       rights: 'Permission denied'
#       notmember: 'This volunteer is not a member of this association'

#     success:
#       deleted: 'Successfuly deleted assoc'
#       kicked: 'Member has been kicked'
#       upgraded: 'Member successfuly upgraded'

#   volunteers:
#     failure:
#       email:
#         unavailable: 'Unavailable email'
#         invalid: 'Invalid email'

#       update: 'Could not update profil'
#       id: 'Unknown volunteer id'
#       research: 'Research field is missing'
#       unfriend: 'No such friendship'
#     success:
#       deleted: 'Successfuly deleted volunteer'
#       unfriend: 'Successfuly deleted friendship'

# events:
#     failure:
#       id: 'Unknow event id'
#       rights: 'Permission denied'
#       wrong_assoc: 'Association not found'
#       not_guest: 'This volunteer is not a guest'
#       join_link_exist: 'You have already applied in this event or you received an invitation'
#       invite_link_exist: 'This volunteer already applied or received an invitation'

#     success:
#       kicked: 'Guest has been kicked'
#       upgraded: 'Guest successfuly upgraded'
#       join_event: 'You successfuly applied to this event'
#       reply_guest: 'You successfuly replied to this guest request'
#       invite_guest: 'You successfuly invited this guest to join your event'
#       reply_invite: 'You successfuly replied to this invitation'

#   notifications:
#     failure:
#       rights: 'Permission denied'
#       addfriend:
#         self: 'Cannot add yourself as friend'
#         error: 'You cannot do that'
#       joinassoc:
#         exist: 'You have already applied in this association or you received an invitation'
#       invitemember:
#         exist: 'This volunteer already applied or received an invitation'

#     success:
#       invitefriend: 'You successfuly sent a friend request'
#       replyfriend: 'You successfuly replied to this friend request'
#       joinassoc: 'You successfuly applied to this association'
#       addmember: 'Member successfuly added'
#       invitemember: 'Member successfuly invited'
#       acceptinvite: 'You successfuly answered to the invitation'

# login:
#     failure:
#       params:
#         password:
#           wrong: 'Wrong password'
#           missing: 'Password is missing'
#         email:
#           wrong: 'Unknown email'
#           missing: 'Email is missing'

#   logout:
#     success: 'User logged out'

#   doc:
#     url: 'Url not found'
#     response: 'See documentation at: /doc'

# "
  end
end
