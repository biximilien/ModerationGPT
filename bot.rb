require "discordrb"
require "logger"

require "./lib/open_ai"
require "./lib/discord"
require "./lib/discord/watchlist_command"
require "./lib/discord/ready_handler"
require "./lib/discord/permission"
require "./lib/backend"
require "./lib/moderation_strategy"
require "./lib/moderation/message_router"
require "./lib/opentelemetry"

# setup logging
$logger = Logger.new(STDOUT)

require "./environment"
Environment.validate!

# create bot
bot = Discordrb::Bot.new token: DISCORD_BOT_TOKEN, intents: :all

# Here we output the invite URL to the console so the bot account can be invited to the channel. This only has to be
# done once, afterwards, you can remove this part if you want
$logger.info("This bot's invite URL is #{bot.invite_url(permission_bits: Discord::Permission::ADMINISTRATOR)}.")
$logger.info("Click on it to invite it to your server.")

include Backend
include OpenAI

initialize_backend()

strategies = []
strategies << WatchListStrategy.new(self)
strategies << RemoveMessageStrategy.new(self)
# strategies << RewriteMessageStrategy.new

watchlist_command = Discord::WatchlistCommand.new(self)
message_router = Moderation::MessageRouter.new(strategies)
ready_handler = Discord::ReadyHandler.new(bot, self)

# bot commands
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

# main loop
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
