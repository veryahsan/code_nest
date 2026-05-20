# frozen_string_literal: true

# Placeholder controller for the upcoming Messages feature. The sidebar
# already surfaces a link here, so this serves a "coming soon" page until
# the real model + UI ships.
class MessagesController < ApplicationController
  before_action :authenticate_user!

  def index; end
end
