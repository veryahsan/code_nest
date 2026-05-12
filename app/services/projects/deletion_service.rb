# frozen_string_literal: true

# Destroys a Project. Sub-resources (documents, languages, tech, remote
# resources) cascade via dependent: :destroy on the model.
module Projects
  class DeletionService < ApplicationService
    def initialize(project:)
      @project = project
    end

    def call
      if @project.destroy
        success(@project)
      else
        failure(@project.errors.full_messages.to_sentence.presence || "could not delete project")
      end
    end
  end
end
