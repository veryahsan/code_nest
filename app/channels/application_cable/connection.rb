# frozen_string_literal: true

module ApplicationCable
  # Authenticates the WebSocket handshake using the same Warden session as
  # the rest of the (Devise-protected) app. Unauthenticated sockets are
  # rejected so channels can rely on `current_user` being present.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private


    def find_verified_user
      env["warden"]&.user(:user) || reject_unauthorized_connection
    end
  end
end
