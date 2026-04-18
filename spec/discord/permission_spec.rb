require "discord"
require "discord/permission"

describe Discord::Permission do
  describe "#MODERATION_BOT" do
    it "includes the permissions needed to moderate text channels" do
      expect(Discord::Permission::MODERATION_BOT).to eq(76_800)
    end

    it "does not include administrator permissions" do
      administrator = 1 << 3

      expect(Discord::Permission::MODERATION_BOT & administrator).to eq(0)
    end
  end
end
