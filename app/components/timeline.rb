class Timeline < ViewComponent::Base
  include ApplicationHelper

  attr_reader :view_object

  def initialize(view_object:)
    @view_object = view_object

    super
  end
end
