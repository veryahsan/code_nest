# frozen_string_literal: true

# Destroys a Team. Memberships cascade via dependent: :destroy on the
# model; project assignments are nullified by dependent: :nullify, so
# projects survive deletion of their team.
module Teams
  class DeletionService < ApplicationService
    def initialize(team:)
      @team = team
    end

    def call
      if @team.destroy
        success(@team)
      else
        failure(@team.errors.full_messages.to_sentence.presence || "could not delete team")
      end
    end
  end
end
