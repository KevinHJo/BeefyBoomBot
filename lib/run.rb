require 'byebug'
require 'discordrb'
require 'dotenv/load'
require_relative 'boom_box'

bot = Discordrb::Commands::CommandBot.new token: ENV["BOT_TOKEN"], prefix: "!"
boom_box = BoomBox.new

bot.command(:join) do |event|
  FileUtils.rm_rf(Dir['lib/songs/*'])
  boom_box.clear_queue

  bot.voice_connect(event.author.voice_channel)
  bot.send_message(event.channel, "🎉 **BeefyBoomBox** has joined the **#{event.author.voice_channel.name}** voice channel! 🎉")
end

bot.command(:kick) do |event|
  event.voice.destroy
  bot.send_message(event.channel, "👋 Goodbye!")
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
    boom_box.remove_song(true_idx)
  rescue
    bot.send_message(event.channel, "⛔ **Unable** to remove song")
  else
    bot.send_message(event.channel, "✅ Song removed **successfully**")
  end
end

bot.command(:queue) do |event|
  if boom_box.queue.empty?
    return bot.send_message(event.channel, "🪹 Looks like there's nothing here yet. Add a song with `!add_song <url>`")
  end

  if event.voice.playing?
    current = [Discordrb::Webhooks::EmbedField.new(
      name: "Currently Playing",
      value: "#{boom_box.currently_playing.sub(/ \[.*\]\.opus/, '')}"
    )]
  else
    current = []
  end

  fields = current + boom_box.queue.map.with_index do |song, idx|
    title = song.sub(/ \[.*\]\.opus/, '')

    Discordrb::Webhooks::EmbedField.new(
      name: "",
      value: "#{idx+1}: **#{title}**",
      inline: false
    )
  end

  embed = Discordrb::Webhooks::Embed.new(
    title: "🎵🎶 __YOUR SONG QUEUE__ 🎶🎵",
    fields: fields
  )

  bot.send_message(event.channel, "", false, embed)
end

bot.command(:current) do |event|
  if event.voice.playing?
    embed = Discordrb::Webhooks::Embed.new(
      title: "",
      fields: [Discordrb::Webhooks::EmbedField.new(name: "Currently Playing", value: "🎵 #{boom_box.format_song_name(boom_box.currently_playing)}")]
    )

    bot.send_message(event.channel, "", false, embed)
  else
    bot.send_message(event.channel, "🙉 Nothing currently playing. Use `!add_song <url>` to add songs to the queue, or `!play <url>` to play a single song!")
  end
end

bot.command(:play) do |event, url|
  if url
    begin
      song = boom_box.download_song_file(url)
    rescue
      bot.send_message(event.channel, "😢 Something went wrong. Please try again")
      return
    else
      path = "lib/songs/#{song}"

      bot.send_message(event.channel, "▶️ Now playing: **#{boom_box.format_song_name(song)}**")
      boom_box.currently_playing = song
      boom_box.source = 'single'

      event.voice.play_file(path)
      boom_box.delete_song_file(boom_box.currently_playing) unless boom_box.queue.include?(song)
      return
    end
  end

  if event.voice.playing? && !url
    event.voice.continue
    bot.send_message(event.channel, "▶️ **Continuing**...")
  else
    boom_box.source = 'queue'

    while !boom_box.queue.empty?
      song = boom_box.queue[0]
      path = Dir["lib/songs/**/*"].find { |file| file.include?(song) }

      bot.send_message(event.channel, "▶️ Now playing: **#{boom_box.format_song_name(song)}**")
      boom_box.currently_playing = song
      event.voice.play_file(path)
      boom_box.remove_song(0)
    end

    FileUtils.rm_rf(Dir['lib/songs/*'])
    boom_box.source = 'single'
    bot.send_message(event.channel, "Thanks for listening! 😊")
  end
end

bot.command(:pause) do |event|
  event.voice.pause
  bot.send_message(event.channel, "⏸️ **Pausing**...")
end

bot.command(:skip) do |event|
  if !event.voice.playing?
    return
  elsif boom_box.queue.empty?
    bot.send_message(event.channel, "🤷‍♀️ No songs in your queue")
    return
  end

  if !boom_box.playing_from_queue?
    bot.send_message(event.channel, "⏭️ **Skipping**... Now playing songs from your queue")
    event.voice.stop_playing(true)
    bot.execute_command(:play, event, [])
  else
    bot.send_message(event.channel, "⏭️ **Skipping**...")
    event.voice.stop_playing(true)
    return
  end
end

bot.command(:stop) do |event|
  event.voice.stop_playing(true)
  bot.send_message(event.channel, "⏹️ **Stopping Music**")
end

bot.run
