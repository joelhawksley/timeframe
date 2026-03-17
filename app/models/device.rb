# frozen_string_literal: true

class Device < ActiveRecord::Base
  SUPPORTED_MODELS = {
    "visionect_13" => {name: "Visionect Place & Play 13\"", template: "thirteen"},
    "boox_mira_pro" => {name: "Boox Mira Pro 25.3\"", template: "mira"}
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :model, presence: true, inclusion: {in: SUPPORTED_MODELS.keys}

  def model_name_label
    SUPPORTED_MODELS.dig(model, :name)
  end

  def display_path
    "/accounts/me/displays/#{name}"
  end
end
