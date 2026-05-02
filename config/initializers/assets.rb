# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Importmap pins resolve against the load path (see javascript_importmap_tags).
Rails.application.config.assets.paths << Rails.root.join("app/javascript")
