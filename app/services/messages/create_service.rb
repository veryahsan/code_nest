# frozen_string_literal: true

# Persists a message authored by a participant of a conversation. The
# broadcast to subscribers is handled by the Message model's
# after_create_commit hook, so both HTTP and Action Cable paths fan out
# identically.
#
# Messages are stored as canonical plain text in `body` (used for mentions,
# notification previews and search). When the composer sends formatted Trix
# output, the HTML is sanitized against an allowlist and stored in `body_html`
# only if it actually carries formatting; the plain text is always derived from
# the sanitized markup so the two columns stay in sync.
#
# @mentions are resolved and persisted (as MessageMention rows) inside the
# same transaction as the message, so the after_create_commit event sees a
# committed, queryable mention set rather than re-parsing the body downstream.
module Messages
  class CreateService < ApplicationService
    # Matches an @handle token. The negative lookbehind keeps it from matching
    # the local-part of an email address (e.g. "bob@alice").
    MENTION_PATTERN = /(?<!\w)@([a-z0-9_]+)/i

    # Tags Trix can emit that we allow through. Attachments/figures and anything
    # else are dropped by the sanitizer.
    ALLOWED_TAGS = %w[strong em b i u del a ul ol li blockquote pre h1 br div].freeze
    ALLOWED_ATTRIBUTES = %w[href].freeze

    # Tags that mean the message carries real formatting. `div`/`br` are how Trix
    # wraps even plain text, so they don't count.
    FORMATTING_TAGS = %w[strong em b i u del a ul ol li blockquote pre h1].freeze

    # Elements pruned with their contents before allowlist sanitizing, so their
    # inner text (e.g. a script body) never survives as stray text.
    DANGEROUS_TAGS = %w[script style iframe object embed template noscript].freeze

    def initialize(conversation:, user:, body: nil, body_html: nil)
      @conversation = conversation
      @user = user
      @body = body
      @body_html = body_html
    end

    def call
      unless @conversation.participant?(@user)
        return failure("you are not a participant of this conversation")
      end

      clean_html = sanitized_html
      plain = plain_text(clean_html)

      message = @conversation.messages.new(
        user: @user,
        body: plain,
        body_html: formatted?(clean_html) ? clean_html : nil,
      )

      saved = Message.transaction do
        next false unless message.save

        persist_mentions(message)
        true
      end

      if saved
        success(message)
      else
        failure(message.errors.full_messages.to_sentence.presence || "could not send message")
      end
    end

    private

    # Sanitized rich HTML, or nil when no rich content was supplied. Dangerous
    # elements are pruned with their contents first so the allowlist pass can't
    # leave behind stray script/style text.
    def sanitized_html
      return nil if @body_html.blank?

      fragment = Nokogiri::HTML5.fragment(@body_html)
      fragment.css(DANGEROUS_TAGS.join(",")).each(&:remove)

      sanitizer
        .sanitize(fragment.to_html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
        .to_s
        .strip
        .presence
    end

    def sanitizer
      @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
    end

    # Canonical plain text. Derived from the sanitized HTML (block boundaries
    # become newlines) when rich content was sent, otherwise the raw body.
    def plain_text(clean_html)
      return @body.to_s.strip if clean_html.blank?

      with_breaks = clean_html
                    .gsub(%r{<br\s*/?>}i, "\n")
                    .gsub(%r{</(?:div|p|li|blockquote|pre|h1)>}i, "\n")
      text = ActionController::Base.helpers.strip_tags(with_breaks)
      CGI.unescapeHTML(text).gsub(/[ \t]+\n/, "\n").strip
    end

    # True when the sanitized HTML carries formatting worth persisting (so plain
    # text wrapped by Trix in a bare <div> is stored as plain text, not HTML).
    def formatted?(clean_html)
      return false if clean_html.blank?

      Nokogiri::HTML5.fragment(clean_html).css(FORMATTING_TAGS.join(",")).any?
    end

    def persist_mentions(message)
      handles = message.body.to_s.scan(MENTION_PATTERN).flatten.map(&:downcase).uniq
      return if handles.empty?

      user_ids = @conversation.participants
                              .joins(:employee)
                              .where(employees: { handle: handles })
                              .where.not(id: message.user_id)
                              .pluck(:id)
      return if user_ids.empty?

      now = Time.current
      rows = user_ids.map do |uid|
        { message_id: message.id, mentioned_user_id: uid, created_at: now }
      end
      MessageMention.insert_all(rows)
    end
  end
end
