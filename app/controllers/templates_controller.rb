# frozen_string_literal: true

class TemplatesController < ApplicationController
  def thirteen
    render "thirteen", locals: { view_object: view_object }, layout: "display"
  end

  private

  def view_object
    out = User.last.render_json_payload
    out[:error_messages] = User.last.alerts

    out
  end
end

# TODO check device battery levels