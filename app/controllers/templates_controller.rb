# frozen_string_literal: true

class TemplatesController < ApplicationController
  def show
    respond_to do |format|
      format.html do
        render(
          html: Slim::Template.new(
            Rails.root.join("app", "views", "image_templates", "#{params[:id]}.slim")
          ).render(
            Object.new,
            view_object: view_object,
            small: params[:id] != "mira_pro_vert"
          ).html_safe, layout: false
        )
      end
    end
  end

  private

  def view_object
    out = User.last.render_json_payload
    out[:error_messages] = User.last.alerts

    out
  end
end

# TODO check device battery levels