require "net/http"
require "google_ai/transport"

describe GoogleAI::Transport do
  subject(:transport) { described_class.new(api_key: "google-key") }

  let(:span) { instance_double("Span", add_event: true, set_attribute: true) }
  let(:http) { instance_double("Net::HTTP") }
  let(:response) { instance_double(Net::HTTPSuccess, body: '{"ok":true}', code: "200", is_a?: true) }

  before do
    allow(Telemetry).to receive(:in_span).and_yield(span)
    allow(Net::HTTP).to receive(:new).and_return(http)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:request).and_return(response)
  end

  it "posts generateContent JSON with a Google API key header" do
    result = transport.generate_content(model: "gemini-test", payload: { contents: [] })

    request = request_sent_to_http
    expect(result).to eq("ok" => true)
    expect(request["Content-Type"]).to eq("application/json")
    expect(request["x-goog-api-key"]).to eq("google-key")
    expect(request.path).to eq("/v1beta/models/gemini-test:generateContent")
  end

  it "raises a normalized error when Google returns invalid JSON" do
    allow(response).to receive(:body).and_return("not json")

    expect { transport.generate_content(model: "gemini-test", payload: {}) }.to raise_error(
      RuntimeError,
      "Google AI API returned invalid JSON",
    )
  end

  def request_sent_to_http
    sent_request = nil
    expect(http).to have_received(:request) { |request| sent_request = request }
    sent_request
  end
end
