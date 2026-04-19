require "discordrb"
require "logger"

require_relative "environment"
require_relative "lib/application"
require_relative "lib/discord"
require_relative "lib/discord/watchlist_command"
require_relative "lib/discord/ready_handler"
require_relative "lib/discord/permission"
require_relative "lib/moderation_strategy"
require_relative "lib/moderation/message_router"
require_relative "lib/telemetry"

$logger = Logger.new(STDOUT)

Environment.validate!

bot = Discordrb::Bot.new token: Environment.discord_bot_token, intents: :all

$logger.info("This bot's invite URL is #{bot.invite_url(permission_bits: Discord::Permission::MODERATION_BOT)}.")
$logger.info("Click on it to invite it to your server.")

app = ModerationGPT::Application.new

strategies = [
  WatchListStrategy.new(app),
  RemoveMessageStrategy.new(app),
]

watchlist_command = Discord::WatchlistCommand.new(app)
message_router = Moderation::MessageRouter.new(strategies)
ready_handler = Discord::ReadyHandler.new(bot, app)

bot.message do |event|
  next if event.user.current_bot?

  $logger.info("Message from #{event.user.name} (#{event.user.id})")
  $logger.info(event.message.content)

  if watchlist_command.matches?(event)
    watchlist_command.handle(event)
  else
    message_router.handle(event)
  end
end

bot.ready do |event|
  ready_handler.handle(event)
end

begin
  at_exit { bot.stop }
  bot.run
rescue Interrupt
  $logger.info("Exiting...")
  exit
end
