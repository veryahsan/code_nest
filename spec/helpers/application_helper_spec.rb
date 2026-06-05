# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#highlight_mentions" do
    it "wraps a known handle in a styled span" do
      html = helper.highlight_mentions("hey @alice", handles: ["alice"])

      expect(html).to include("<span")
      expect(html).to include("@alice")
    end

    it "leaves an unknown handle as plain text" do
      html = helper.highlight_mentions("hey @bob", handles: ["alice"])

      expect(html).not_to include("<span")
      expect(html).to include("@bob")
    end

    it "highlights the viewer's own handle distinctly" do
      mine  = helper.highlight_mentions("@alice", handles: ["alice"], current_handle: "alice")
      other = helper.highlight_mentions("@alice", handles: ["alice"], current_handle: "bob")

      expect(mine).not_to eq(other)
    end

    it "escapes HTML in the surrounding body" do
      html = helper.highlight_mentions("<script>alert(1)</script> @alice", handles: ["alice"])

      expect(html).to include("&lt;script&gt;")
      expect(html).not_to include("<script>")
    end

    it "matches handles case-insensitively" do
      html = helper.highlight_mentions("hi @Alice", handles: ["alice"])

      expect(html).to include("<span")
    end
  end

  describe "#highlight_mentions_html" do
    it "highlights mentions inside text nodes while keeping formatting tags" do
      html = helper.highlight_mentions_html("<strong>hey</strong> @alice", handles: ["alice"])

      expect(html).to include("<strong>hey</strong>")
      expect(html).to include("<span")
      expect(html).to include("@alice")
    end

    it "does not rewrite mentions inside links" do
      html = helper.highlight_mentions_html('<a href="/x">@alice</a>', handles: ["alice"])

      expect(html).to include("</a>")
      expect(html).not_to include("<span")
    end

    it "leaves an unknown handle as plain text" do
      html = helper.highlight_mentions_html("<em>@bob</em>", handles: ["alice"])

      expect(html).to include("<em>")
      expect(html).not_to include("<span")
    end

    it "highlights the viewer's own handle distinctly" do
      mine  = helper.highlight_mentions_html("<em>@alice</em>", handles: ["alice"], current_handle: "alice")
      other = helper.highlight_mentions_html("<em>@alice</em>", handles: ["alice"], current_handle: "bob")

      expect(mine).not_to eq(other)
    end
  end
end
