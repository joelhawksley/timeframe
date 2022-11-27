# frozen_string_literal: true

namespace :fetch do
  task all: :environment do
    GoogleAccount.all.each(&:refresh!)
    User.all.each do |user|
      user.fetch
    end
  end
end
