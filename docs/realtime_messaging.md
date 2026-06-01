# Real-time Messaging — Action Cable & Conversation WebSocket Logic

This document describes how real-time messaging is wired in Code Nest: the
Action Cable connection, the `ConversationChannel`, the broadcast pipeline,
and the front-end consumer/Stimulus controller that render messages live.

## Overview

Messaging supports two conversation kinds:

- **Direct messages (DMs)** — exactly two participants, deduplicated per pair.
- **Groups** — up to `Conversation::GROUP_CAPACITY` (50) participants. Every
  `Project` automatically owns one group conversation whose roster mirrors
  the project's membership.

Delivery uses a **custom channel + client-side rendering** approach: the
server broadcasts JSON payloads over a Redis-backed Action Cable stream, and a
Stimulus controller renders them into the DOM. There are no Turbo Stream
templates in the hot path — the client owns rendering.

```
Browser (Stimulus) ──ws──▶ /cable ──▶ ConversationChannel.stream_for(conversation)
       ▲                                            │
       │   JSON { message: {...} }                  │  Redis pub/sub fan-out
       └────────────────────────────────────────────┘
                         ▲
        Message#after_create_commit ─▶ ConversationChannel.broadcast_to(conversation, ...)
```

## Components

### 1. Connection authentication — `app/channels/application_cable/connection.rb`

The WebSocket handshake is authenticated using the **same Warden session** as
the rest of the Devise-protected app, so no separate token scheme is needed.

```ruby
module ApplicationCable
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
```

- `identified_by :current_user` makes `current_user` available to every
  channel on the connection.
- Unauthenticated sockets are rejected, so channels can assume a present user.
- `:user` is the Devise scope.

### 2. The channel — `app/channels/conversation_channel.rb`

A single channel handles one conversation per subscription. **Streaming is
gated on participation**: a socket only starts streaming after we verify the
connected user is a participant (or a super admin). This is what prevents the
Redis fan-out from leaking messages to non-members.

```ruby
class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = find_conversation
    conversation ? stream_for(conversation) : reject
  end

  def unsubscribed
    stop_all_streams
  end

  # data => { "body" => "..." }
  def speak(data)
    conversation = find_conversation
    return if conversation.nil?

    Messages::CreateService.call(
      conversation: conversation,
      user: current_user,
      body: data["body"],
    )
  end

  private

  def find_conversation
    conversation = Conversation.find_by(id: params[:id])
    return nil if conversation.nil?
    return conversation if current_user.super_admin? || conversation.participant?(current_user)

    nil
  end
end
```

- `subscribed` → `stream_for(conversation)` only for participants; otherwise
  `reject`.
- `speak(data)` lets clients send a message over the socket. It delegates to
  `Messages::CreateService`, which re-checks participation and persists the
  message. The actual broadcast is **not** done here — see below.

### 3. Broadcast on persist — `app/models/message.rb`

Broadcasting is triggered by the model's `after_create_commit` hook, so **both**
paths that create a message — the WebSocket `#speak` action and the HTTP
fallback (`Conversations::MessagesController#create`) — fan out identically.

```ruby
class Message < ApplicationRecord
  after_create_commit :broadcast_to_conversation

  def broadcast_payload
    {
      id: id,
      conversation_id: conversation_id,
      user_id: user_id,
      sender_label: sender_label,
      body: body,
      created_at: created_at.iso8601,
    }
  end

  private

  def broadcast_to_conversation
    ConversationChannel.broadcast_to(conversation, message: broadcast_payload)
  end
end
```

The payload is plain JSON; the client decides how to render it (including
whether a message is "mine" by comparing `user_id`).

### 4. Message creation service — `app/services/messages/create_service.rb`

Single source of truth for "create a message":

- Verifies the author is a participant of the conversation.
- Strips and validates the body (presence + `Message::MAX_LENGTH`).
- Returns a `Result` (`success?`/`failure?`). The broadcast happens via the
  model hook, keeping the service free of delivery concerns.

### 5. Front-end consumer — `app/javascript/channels/consumer.js`

```js
import { createConsumer } from "@rails/actioncable"
export default createConsumer()
```

`@rails/actioncable` is pinned via importmap:

```ruby
# config/importmap.rb
pin "@rails/actioncable", to: "actioncable.esm.js"
pin_all_from "app/javascript/channels", under: "channels"
```

### 6. Stimulus controller — `app/javascript/controllers/conversation_controller.js`

Subscribes to `ConversationChannel`, appends incoming messages, and sends new
ones over the socket.

- `static values = { id: Number, userId: Number }` — the conversation id and
  the viewer's user id (used to align "my" messages right).
- `connect()` creates the subscription:
  `consumer.subscriptions.create({ channel: "ConversationChannel", id }, { received })`.
- `received(data)` → `appendMessage(data.message)`; messages are inserted with
  `textContent` (never `innerHTML`) to avoid XSS.
- `submit(event)` → `preventDefault()` then `subscription.perform("speak", { body })`.

Because the sender is also a subscriber, their own message comes back over the
broadcast and is appended once — no optimistic-update bookkeeping needed.

### 7. Views & HTTP fallback

`app/views/conversations/show.html.erb` wires the controller and a composer:

```erb
<div data-controller="conversation"
     data-conversation-id-value="<%= @conversation.id %>"
     data-conversation-user-id-value="<%= current_user.id %>">
  <div data-conversation-target="list">…server-rendered history…</div>

  <%= form_with url: conversation_messages_path(@conversation), scope: :message,
        data: { conversation_target: "form", action: "submit->conversation#submit" } do |f| %>
    <%= f.text_field :body, data: { conversation_target: "input" } %>
  <% end %>
</div>
```

The composer posts to `Conversations::MessagesController#create`. With JS, the
Stimulus controller intercepts `submit` and sends over the socket instead; the
HTTP POST is a **progressive-enhancement fallback** that still works without JS
(it persists via the same service, which broadcasts via the model hook).

## Routing

```ruby
# config/routes.rb
get "messages", to: "conversations#index", as: :messages

resources :conversations, only: %i[index show new create] do
  resources :messages, only: %i[index create], controller: "conversations/messages"
  member { patch :read }
end
```

Action Cable is mounted at the default `/cable` (see `config/cable.yml`).

## Authorization model

| Layer                         | Check                                                        |
|-------------------------------|-------------------------------------------------------------|
| `Connection`                  | Warden session must resolve a user, else reject the socket. |
| `ConversationChannel#subscribed` | User must be a participant (or super admin) to `stream_for`. |
| `Messages::CreateService`     | Author must be a participant to persist.                    |
| `ConversationPolicy`          | `show?`/`send_message?` require participation; `Scope` returns only the user's conversations. |

## Infrastructure

`config/cable.yml`:

- **development** — `redis` when `REDIS_URL` is set, else `async`.
- **test** — `test` adapter (enables `have_broadcasted_to` matchers).
- **production** — `redis` with a `code_nest_production` channel prefix.

No infrastructure change is required beyond the Redis already used for caching
and Sidekiq.

## Project ↔ group conversation sync

- `Project#after_create_commit` calls `ensure_group_conversation`, creating one
  group `Conversation` per project (titled after the project).
- `ProjectMembership` callbacks keep the roster in sync:
  - `after_create_commit :join_project_group` → adds the user as a
    `ConversationParticipant` of the project's group.
  - `after_destroy_commit :leave_project_group` → removes them.
- Capacity (50) is enforced on both `ProjectMembership` (on create) and
  `ConversationParticipant` (group cap), so a project's group never exceeds the
  limit.

## End-to-end message flow

1. User opens a conversation → `ConversationsController#show` renders history
   and marks the viewer's participant row read.
2. Stimulus `connect()` opens a subscription to `ConversationChannel` for that
   conversation id; the channel verifies participation and `stream_for`s it.
3. User submits the composer → Stimulus `perform("speak", { body })`.
4. `ConversationChannel#speak` → `Messages::CreateService` persists the message.
5. `Message#after_create_commit` → `ConversationChannel.broadcast_to(conversation, …)`.
6. Redis fans the JSON payload out to every subscriber (including the sender).
7. Each client's `received` callback appends the message to the list.

## Tests

- `spec/channels/conversation_channel_spec.rb` — participant gating + `#speak`.
- `spec/models/message_spec.rb` — `have_broadcasted_to(...).from_channel(...)`.
- `spec/services/conversations/*`, `spec/services/messages/*` — service logic.
- `spec/requests/conversations_spec.rb` — index/show/create + message POST.
- `spec/integration/project_group_sync_spec.rb` — project ↔ group roster sync.
