class Timeline < ViewComponent::Base
  include ApplicationHelper
  
  attr_reader :view_object
  attr_reader :icon_set

  def initialize(view_object:, icon_set: "solid")
    @view_object = view_object
    @icon_set = icon_set
  end
end