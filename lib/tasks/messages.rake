# frozen_string_literal: true

namespace :messages do
  # Converts legacy plain-text "@handle" mentions (stored before the Lexxy +
  # Action Text migration) into Action Text mention attachments, so old
  # messages render with the same resolved pills as new ones. Best-effort and
  # idempotent: only messages without rich content are touched, and only
  # handles that map to a current participant are converted.
  desc "Backfill legacy plain-text @mentions into Action Text mention attachments (idempotent)"
  task backfill_mentions: :environment do
    mention_pattern = /(?<!\w)@([a-z0-9_]+)/i
    content_type = Employee::MENTION_CONTENT_TYPE

    escape_with_breaks = lambda do |text|
      ERB::Util.html_escape(text.to_s).gsub(/\r?\n/, "<br>")
    end

    converted = 0

    Message.includes(:rich_text_body_text, conversation: {}).find_each do |message|
      next if message.rich? # already Action Text

      body = message.body.to_s
      next unless body.match?(mention_pattern)

      employees_by_handle = Employee
                            .where(user_id: message.conversation.participants.select(:id))
                            .index_by { |employee| employee.handle.to_s.downcase }
      next if employees_by_handle.empty?

      html = +"<div>"
      cursor = 0
      replaced = false

      body.scan(mention_pattern) do
        match = Regexp.last_match
        html << escape_with_breaks.call(body[cursor...match.begin(0)])

        if (employee = employees_by_handle[match[1].downcase])
          html << %(<action-text-attachment sgid="#{employee.attachable_sgid}" content-type="#{content_type}"></action-text-attachment>)
          replaced = true
        else
          html << escape_with_breaks.call(match[0])
        end

        cursor = match.end(0)
      end
      html << escape_with_breaks.call(body[cursor..]) if cursor < body.length
      html << "</div>"

      next unless replaced

      message.body_text = html
      # Skip validations/create callbacks: `body` is unchanged, and we don't want
      # to re-broadcast historical messages.
      message.save!(validate: false)
      converted += 1
    end

    puts "Backfilled mentions on #{converted} message(s)."
  end
end
