require 'byebug'
require 'discordrb'
require 'dotenv/load'
require_relative 'boom_box'

bot = Discordrb::Commands::CommandBot.new token: ENV["BOT_TOKEN"], prefix: "!"
boom_box = BoomBox.new

bot.command(:ping) do |event|
  event.respond "Pong!"
end

bot.command(:join) do |event|
  FileUtils.rm_rf(Dir['lib/songs/*'])
  boom_box.clear_queue

  bot.voice_connect(event.author.voice_channel)
  bot.send_message(event.channel, "🎉 **BeefyBoomBox** has joined the **#{event.channel.name}** voice channel! 🎉")
end

bot.command(:add_song, min_args: 1) do |event, url|
  begin
    boom_box.add_song(url)
  rescue
    bot.send_message(event.channel, "⛔ **Unable** to add song")
  else
    bot.send_message(event.channel, "✅ Song added **successfully** ")
  end
end

bot.command(:remove_song, min_args: 1) do |event, idx|
  true_idx = idx.to_i - 1

  begin
    boom_box.delete_song_file(boom_box.queue[true_idx])
    boom_box.remove_song(true_idx)
  rescue
    bot.send_message(event.channel, "⛔ **Unable** to remove song")
  else
    bot.send_message(event.channel, "✅ Song removed **successfully**")
  end
end

bot.command(:queue) do |event|
  embed = Discordrb::Webhooks::Embed.new(
    title: "🎵🎶 __YOUR SONG QUEUE__ 🎶🎵",
    fields: boom_box.queue.map.with_index do |song, idx|
      title = song.sub(/ \[.*\]\.opus/, '')

      Discordrb::Webhooks::EmbedField.new(
        name: "",
        value: "#{idx+1}: **#{title}**",
        inline: false
      )
    end
  )

  bot.send_message(event.channel, "", false, embed)
end

bot.command(:play) do |event|
  if event.voice.playing?
    event.voice.continue
    bot.send_message(event.channel, "▶️ **Continuing**...")
  else
    while !boom_box.queue.empty?
      song = boom_box.queue[0]
      path = Dir["lib/songs/**/*"].find { |file| file.include?(song) }

      boom_box.currently_playing = song
      boom_box.remove_song(0)
      event.voice.play_file(path)
    end

    bot.send_message(event.channel, "Thanks for listening! 😊")
  end
end

bot.command(:pause) do |event|
  event.voice.pause
  bot.send_message(event.channel, "⏸️ **Pausing**...")
end

bot.command(:skip) do |event|
  return unless event.voice.playing?

  boom_box.delete_song_file(boom_box.currently_playing)
  event.voice.stop_playing(true)

  bot.send_message(event.channel, "⏭️ **Skipping**...")
end

bot.run
