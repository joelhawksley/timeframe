namespace :fetch do
  task all: :environment do
    User.all.map(&:fetch)
  end
end
