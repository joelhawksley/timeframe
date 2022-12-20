# frozen_string_literal: true

class TemplatesController < ApplicationController
  def thirteen
    render "thirteen", locals: { view_object: view_object }, layout: "layouts/display"
  end

  def mira
    render "mira", locals: { view_object: view_object }, layout: "display"
  end

  private

  def view_object
    User.last.render_json_payload
  end
end
