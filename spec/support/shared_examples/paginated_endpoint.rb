# frozen_string_literal: true

# Shared assertions for paginated JSON:API index endpoints.
#
# Each consumer is responsible for setting up:
#   - `path`     – the URL to GET (e.g. "/api/v1/teams")
#   - `headers`  – request headers including auth
#   - any DB fixtures the path needs to return at least one record
#
# The example only checks the *envelope* (meta/links structure + clamps),
# not the contents of `data` — individual specs cover the body.
#
# Usage:
#
#   it_behaves_like "a paginated JSON:API endpoint" do
#     let(:path)    { "/api/v1/teams" }
#     let(:headers) { auth_headers_for(admin) }
#   end
RSpec.shared_examples "a paginated JSON:API endpoint" do
  let(:meta_keys) { %w[current_page per_page total_pages total_count] }

  it "returns Pagy metadata and links" do
    get path, headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body).to include("meta", "links")
    expect(body["meta"]).to include(*meta_keys)
    expect(body["links"]).to include("self", "first", "last")
  end

  it "clamps ?per_page= to the configured max_limit (100)" do
    get path, params: { per_page: 200 }, headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    # Pagy 43.x caps the user-supplied per_page at Pagy::OPTIONS[:max_limit].
    expect(body["meta"]["per_page"]).to be <= 100
  end

  it "does not error on an out-of-range ?page=" do
    get path, params: { page: 999 }, headers: headers
    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    expect(body["data"]).to eq([])
    # Pagy still reports the navigable structure so the client can recover.
    expect(body["links"]).to include("first", "last")
  end
end
