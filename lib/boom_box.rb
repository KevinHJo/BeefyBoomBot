class BoomBox
  attr_accessor :queue, :currently_playing, :source

  def initialize
    @queue = {}
    @currently_playing = ''
    @source = 'single'
  end

  def add_song(url:, server_id:)
    raise StandardError.new "This is a playlist" if url.include?("list=")

    song = download_song_file(url: url, server_id: server_id)
    @queue[server_id] ||= []
    @queue[server_id] << song
  end

  def download_song_file(url:, server_id:)
    limiter = 0

    begin
      song = YtDlp::Video.new(url, extract_audio: true, output: "\"songs/#{server_id}/%(title)s.%(opus)s\"").download
    rescue => e
      puts e.full_message(highlight: true, order: :top)

      if limiter <= 5
        limiter += 1
        puts "Oh no! Something went wrong. Trying download again..."
        retry
      end
    end

    song.slice!("songs/#{server_id}/")
    return song
  end

  def remove_song(server_id:, idx:)
    song = @queue[server_id][idx]
    @queue[server_id].delete_at(idx)
    delete_song_file(song: song, server_id: server_id) unless @queue.include?(song)
  end

  def delete_song_file(song:, server_id:)
    path = "songs/#{server_id}/#{song}.opus"
    File.delete(path) if File.exist?(path)
  end

  def clear_queue(server_id:)
    @queue.delete(server_id)
  end

  def format_song_name(song)
    song.sub(/\.NA/, '')
  end

  def playing_from_queue?
    source === 'queue'
  end
end
