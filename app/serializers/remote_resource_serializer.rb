# frozen_string_literal: true

# Important: this serializer NEVER includes the decrypted credentials.
# Even API consumers with admin role can read them only via a dedicated
# endpoint that goes through RemoteResourcePolicy#view_credentials? —
# the JSON:API resource representation only carries metadata.
class RemoteResourceSerializer < ApplicationSerializer
  set_type :remote_resource

  attributes :name, :kind, :url, :created_at, :updated_at
  attribute :project_id
end
