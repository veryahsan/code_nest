# frozen_string_literal: true

# Lockbox is used to encrypt sensitive fields such as RemoteResource credentials.
# Generate a master key once with `Lockbox.generate_key` and store it in env.

Lockbox.master_key = ENV["LOCKBOX_MASTER_KEY"] if ENV["LOCKBOX_MASTER_KEY"].present?
