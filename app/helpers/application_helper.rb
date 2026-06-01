# frozen_string_literal: true

module ApplicationHelper
  # Turbo Frame that holds page content inside the signed-in chrome.
  # Sidebar / topbar links target this frame; see +main_frame_data+.
  MAIN_CONTENT_FRAME = "main"

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

  # ── Avatar helpers ────────────────────────────────────────────────────────────

  # Renders the user's avatar image if one is attached, otherwise a coloured
  # circle showing their name initials (employee display name, or email local-part).
  #
  # Usage:
  #   <%= user_avatar_tag(current_user) %>
  #   <%= user_avatar_tag(current_user, variant: :profile, css: "h-20 w-20") %>
  def user_avatar_tag(user, variant: :thumb, css: "h-8 w-8")
    label = user_avatar_label(user)
    base_classes = "#{css} rounded-full object-cover"
    if user.avatar.attached?
      image_tag user.avatar.variant(variant),
                class: base_classes,
                alt: "#{label} avatar"
    else
      initials_avatar_tag(initials_for(label), label: label, css: css)
    end
  end

  # Initials-only avatar for people who don't have a User record yet (e.g. pending invitations).
  def email_avatar_tag(email, css: "h-8 w-8")
    label = email.to_s.split("@").first
    initials_avatar_tag(initials_for(label), label: email, css: css)
  end

  def user_avatar_label(user)
    user.employee&.display_name.presence || user.email.to_s.split("@").first
  end

  def initials_for(name)
    parts = name.to_s.split(/\s+/).grep(/\S/)
    case parts.length
    when 0 then "?"
    when 1 then parts.first[0].upcase
    else parts.first(2).map { |part| part[0] }.join.upcase
    end
  end

  def initials_avatar_tag(initials, label:, css: "h-8 w-8")
    content_tag :span, initials,
                class: "#{css} inline-flex shrink-0 items-center justify-center rounded-full bg-brand-600 text-xs font-semibold text-white select-none",
                aria: { label: "#{label} avatar" }
  end

  # ── Pagination helpers ────────────────────────────────────────────────────────

  # Render the shared pagination partial for a Pagy::Offset instance.
  # Returns nil if there's only one page, so views can call this unconditionally.
  #
  # Usage:  <%= pagination_tag(@pagy) %>
  def pagination_tag(pagy)
    return if pagy.nil? || pagy.last <= 1

    render "shared/pagination", pagy: pagy
  end

  # Compact, numbered series for the pagination bar (page numbers + gap markers).
  # Mirrors Pagy's internal `series` algorithm but lives here so the view doesn't
  # need to reach into Pagy's protected methods.
  #
  # Returns an Array of:
  #   Integer  – render as a link to that page
  #   String   – current page (render as static highlighted label)
  #   :gap     – render as an ellipsis separator
  #
  # Examples (with default 7 slots):
  #   page 1 of 3   -> [1, "1", 2, 3] — wait, page 1 -> ["1", 2, 3]
  #   page 5 of 36  -> [1, :gap, 4, "5", 6, :gap, 36]
  def pagination_series(pagy, slots: 7)
    last    = pagy.last
    current = pagy.page
    return (1..last).to_a.map { |p| p == current ? p.to_s : p } if last <= slots

    half = (slots - 1) / 2
    start =
      if current <= half
        1
      elsif current > last - slots + half
        last - slots + 1
      else
        current - half
      end

    series = (start...(start + slots)).to_a
    series[0]  = 1
    series[1]  = :gap unless series[1] == 2
    series[-2] = :gap unless series[-2] == last - 1
    series[-1] = last
    idx        = series.index(current)
    series[idx] = current.to_s if idx
    series
  end

  # ── Turbo helpers ─────────────────────────────────────────────────────────────

  def main_content_frame_id
    MAIN_CONTENT_FRAME
  end

  # +data-turbo-frame+ for links outside the main frame (sidebar, mobile brand).
  def main_frame_data(extra = {})
    { turbo_frame: main_content_frame_id }.merge(extra)
  end

  # Wraps flash + page content in the persistent main Turbo Frame.
  # data-turbo-action="advance" makes every frame navigation push a real
  # history entry so the browser URL stays in sync with the displayed page.
  def main_content_frame(&block)
    page_title_text = content_for(:title).presence || "Code Nest"
    turbo_frame_tag(
      main_content_frame_id,
      class: "contents",
      data: {
        turbo_action: "advance",
        controller: "frame-title",
        frame_title_title_value: page_title_text
      }
    ) do
      safe_join([ render("shared/flash"), capture(&block) ])
    end
  end

  # Wrap content in a Turbo Frame for easy partial replacement.
  # Usage: <%= turbo_frame_wrap("project-list") { render @projects } %>
  def turbo_frame_wrap(id, src: nil, loading: nil, &block)
    tag.turbo_frame(id: id,
                    src: src,
                    loading: loading,
                    &block)
  end
end
