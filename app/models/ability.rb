class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= Volunteer.new
    can :create, Volunteer
    user.av_links.each do |av_link|
      if av_link.rights.eql?("owner")
        can :manage, av_link.assoc
      elsif av_link.rights.eql?("admin")
        can :manage, av_link
        can :manage, av_link.assoc
      elsif av_link.rights.eql?("member")
      end
    end

    user.event_volunteers.each do |event_volunteer|
      if event_volunteer.eql?("host")
        can :manage, event_volunteer.event
      elsif event_volunteer.eql?("admin")
      elsif event_volunteer.eql?("member")
      end
    end
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  end
end
