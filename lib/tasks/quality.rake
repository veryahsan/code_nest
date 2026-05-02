# frozen_string_literal: true

namespace :quality do
  desc "Run all quality checks (RuboCop, Brakeman, bundler-audit)"
  task all: %i[rubocop brakeman audit]

  desc "Run RuboCop"
  task :rubocop do
    sh "bundle exec rubocop --parallel"
  end

  desc "Run Brakeman security scanner"
  task :brakeman do
    sh "bundle exec brakeman --no-pager --quiet --exit-on-warn"
  end

  desc "Run bundler-audit"
  task :audit do
    sh "bundle exec bundle-audit check --update"
  end
end
