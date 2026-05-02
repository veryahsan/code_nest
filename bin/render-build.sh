#!/usr/bin/env bash
# Render build script. Runs on every deploy.
set -o errexit

echo "Installing gems..."
bundle install

echo "Precompiling Tailwind + assets..."
bundle exec rails assets:precompile
bundle exec rails assets:clean

echo "Running database migrations..."
bundle exec rails db:prepare
