# frozen_string_literal: true

module ApplicationHelper
  # ── Utility ──────────────────────────────────────────────────────────────────

  # Merge class strings, filtering out nil/false values.
  # Mirrors the popular `clsx` / `cn` pattern from the JS world.
  #
  # Usage:
  #   cn("btn-base", :primary? && "btn-primary", custom_class)
  #   cn("input", errors? && "input-error")
  def cn(*classes)
    classes.flatten.compact.select { |c| c.present? }.join(" ")
  end

  # ── Page helpers ─────────────────────────────────────────────────────────────

  # Set both the <title> tag and yield a heading for the current page.
  # Usage in view: <% page_title "Projects" %>
  def page_title(title)
    content_for(:title) { title }
    title
  end

  # ── Inline component helpers ──────────────────────────────────────────────────
  # These are convenience wrappers that render the component partials
  # when you want an inline call rather than a separate render statement.

  # Render a badge inline.
  # Usage: <%= badge_tag "Active", variant: :success %>
  def badge_tag(label, variant: :neutral, dot: false, extra_class: nil)
    render "components/badge",
      label: label,
      variant: variant,
      dot: dot,
      extra_class: extra_class
  end

  # Render an alert inline.
  # Usage: <%= alert_tag "Saved!", variant: :success, dismissible: true %>
  def alert_tag(message, variant: :info, title: nil, dismissible: false, icon: true, extra_class: nil)
    render "components/alert",
      message: message,
      variant: variant,
      title: title,
      dismissible: dismissible,
      icon: icon,
      extra_class: extra_class
  end

  # Render a spinner inline.
  # Usage: <%= spinner_tag size: :sm %>
  def spinner_tag(size: :md, label: "Loading\u2026", color: nil)
    render "components/spinner", size: size, label: label, color: color
  end

  # ── Form helpers ──────────────────────────────────────────────────────────────

  # Wrap a form field in a consistent label + input + error group.
  #
  # Usage:
  #   <%= form_group_tag label: "Email", required: true,
  #         error: @user.errors[:email].first do %>
  #     <%= f.email_field :email, class: cn("input", @user.errors[:email].any? && "input-error") %>
  #   <% end %>
  def form_group_tag(label: nil, for_id: nil, hint: nil, error: nil,
                     required: false, extra_class: nil, &block)
    # Use the partial + block form, not `render layout:` — inside `form_for`,
    # nested layout renders can duplicate the whole outer form (Rails 8 / AV).
    render "components/form_group",
           locals: {
             label: label, for_id: for_id, hint: hint,
             error: error, required: required, extra_class: extra_class
           },
           &block
  end

  # ── Input class builder ───────────────────────────────────────────────────────

  # Returns the correct CSS classes for an input, including the error state.
  # Usage:  class: input_classes(f.object.errors[:email].any?)
  def input_classes(has_error = false)
    cn("input", has_error && "input-error")
  end

  # ── Turbo helpers ─────────────────────────────────────────────────────────────

  # Wrap content in a Turbo Frame for easy partial replacement.
  # Usage: <%= turbo_frame_wrap("project-list") { render @projects } %>
  def turbo_frame_wrap(id, src: nil, loading: nil, &block)
    tag.turbo_frame(id: id,
                    src: src,
                    loading: loading,
                    &block)
  end
end
