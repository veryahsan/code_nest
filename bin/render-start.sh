#!/usr/bin/env bash
set -o errexit

exec bundle exec puma -C config/puma.rb
