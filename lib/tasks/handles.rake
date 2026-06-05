# frozen_string_literal: true

namespace :handles do
  desc "Backfill employee handles for rows that don't have one yet (idempotent)"
  task backfill: :environment do
    require "set"

    total = 0

    Organisation.find_each do |org|
      taken = org.employees.where.not(handle: nil).pluck(:handle).to_set

      org.employees.where(handle: nil).includes(:user).find_each do |employee|
        base = Employee.normalize_handle(employee.user&.email.to_s.split("@").first).presence || "user"

        handle = base
        while taken.include?(handle)
          handle = "#{base}_#{SecureRandom.alphanumeric(Employee::HANDLE_SUFFIX_LENGTH).downcase}"
        end

        taken << handle
        # update_column skips validations/callbacks; the unique index still guards.
        employee.update_column(:handle, handle)
        total += 1
      end
    end

    puts "Backfilled #{total} employee handle(s)."
  end
end
