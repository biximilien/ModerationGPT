require "discord/review_presenter"

describe Discord::ReviewPresenter do
  subject(:presenter) { described_class.new }

  it "formats empty review lists" do
    expect(presenter.list([], user_id: "456")).to eq("No moderation reviews for <@456>")
  end

  it "formats review entries" do
    entry = {
      created_at: "2026-04-19T12:00:00Z",
      message_id: "111",
      user_id: "456",
      strategy: "RemoveMessageStrategy",
      action: "removed",
      shadow_mode: false,
    }

    expect(presenter.list([entry])).to eq(
      "Moderation reviews:\n" \
      "- 2026-04-19T12:00:00Z live removed <@456> msg=111 via RemoveMessageStrategy",
    )
  end

  it "truncates long rewrite previews" do
    entry = {
      created_at: "2026-04-19T12:00:00Z",
      message_id: "111",
      user_id: "456",
      strategy: "WatchListStrategy",
      action: "would_rewrite",
      shadow_mode: true,
      rewrite: "a" * 140,
    }

    expect(presenter.list([entry])).to eq(
      "Moderation reviews:\n" \
      "- 2026-04-19T12:00:00Z shadow would_rewrite <@456> msg=111 via WatchListStrategy rewrite=#{"#{'a' * 120}...".inspect}",
    )
  end

  it "formats restored content" do
    entry = { user_id: "456", original_content: "Original message" }

    expect(presenter.restored(entry)).to eq("Restored message from <@456>:\nOriginal message")
  end
end
