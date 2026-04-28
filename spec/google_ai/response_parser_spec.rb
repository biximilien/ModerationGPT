require "google_ai/response_parser"

describe GoogleAI::ResponseParser do
  it "extracts candidate text parts" do
    response = {
      "candidates" => [
        { "content" => { "parts" => [{ "text" => "Hello" }, { "text" => " there" }] } }
      ]
    }

    expect(described_class.text(response)).to eq("Hello there")
  end
end
