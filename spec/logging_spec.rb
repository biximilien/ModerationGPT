require "logging"
require "stringio"
require "json"

describe Logging do
  describe ".build_logger" do
    it "formats hash messages as json by default" do
      output = StringIO.new
      logger = described_class.build_logger(output, format: "json")

      logger.info(event: "test_event", value: 3)
      payload = JSON.parse(output.string.lines.last)

      expect(payload).to include(
        "level" => "info",
        "event" => "test_event",
        "value" => 3
      )
      expect(payload).to have_key("timestamp")
    end

    it "formats hash messages in plain text when configured" do
      output = StringIO.new
      logger = described_class.build_logger(output, format: "plain")

      logger.warn(event: "test_event", value: 3)

      expect(output.string).to include("WARN")
      expect(output.string).to include("test_event")
      expect(output.string).to include("value=3")
    end
  end
end
