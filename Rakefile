# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

task(:check) {
  system("bundle exec ordinare --check") &&
    system("bundle exec rubocop -DESP") &&
    system("bundle exec rspec -f d")
}

task default: :check
