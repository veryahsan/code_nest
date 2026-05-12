# frozen_string_literal: true

class ProjectDocumentSerializer < ApplicationSerializer
  set_type :project_document

  attributes :title, :url, :external_id, :metadata, :created_at, :updated_at
  attribute :project_id
end
