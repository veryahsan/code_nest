# frozen_string_literal: true

# Pagy 43.x configuration.
#
# Globally applied to every `pagy(scope, ...)` call. Override per-controller
# with `pagy(scope, limit: 25)` if a screen needs a different page size.
#
# Notes on the option keys (43.x renamed several from earlier versions):
#   :limit       – page size (was :items)
#   :max_limit   – server-side cap on user-supplied ?per_page= values
#   :limit_key   – URL param name for page size (default "limit"); MUST be a String
#   :page_key    – URL param name for page number (default "page");  MUST be a String
#
# Setting :max_limit enables the per-page URL parameter; without it the URL
# param is ignored and pagy uses the default :limit only.
Pagy::OPTIONS[:limit]     = 10
Pagy::OPTIONS[:max_limit] = 100
Pagy::OPTIONS[:limit_key] = "per_page"
Pagy::OPTIONS[:page_key]  = "page"
