require "discord/moderation_command_parser"

describe Discord::ModerationCommandParser do
  subject(:parser) { described_class.new }

  it "recognizes moderation triggers" do
    expect(parser.trigger?("!moderation watchlist")).to eq(true)
    expect(parser.trigger?("hello there")).to eq(false)
  end

  it "parses built-in command arguments" do
    match = parser.parse("!moderation karma add <@456> 2")

    expect(match[:command]).to eq("karma")
    expect(match[:subcommand]).to eq("add")
    expect(match[:user_id]).to eq("456")
    expect(match[:amount]).to eq("2")
  end

  it "parses moderation review commands" do
    match = parser.parse("!moderation review recent 3")

    expect(match[:command]).to eq("review")
    expect(match[:subcommand]).to eq("recent")
    expect(match[:amount]).to eq("3")
  end
end
