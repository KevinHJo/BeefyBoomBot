class BoomBox
  attr_accessor :queue, :currently_playing, :source

  def initialize
    @queue = []
    @currently_playing = ''
    @source = 'single'
  end

  def add_song(url)
    raise StandardError.new "This is a playlist" if url.include?("list=")

    song = download_song_file(url)
    @queue << song
  end

  def download_song_file(url)
    limiter = 0

    begin
      song = YtDlp::Video.new(url, extract_audio: true, output: "\"songs/%(title)s.%(opus)s\"").download
    rescue => e
      puts e.full_message(highlight: true, order: :top)

      if limiter <= 5
        limiter += 1
        puts "Oh no! Something went wrong. Trying download again..."
        retry
      end
    end

    song.slice!("songs/")
    return song
  end

  def remove_song(idx)
    song = @queue[idx]
    @queue.delete_at(idx)
    delete_song_file(song) unless @queue.include?(song)
  end

  def delete_song_file(song)
    File.delete("songs/#{song}") if File.exist?("songs/#{song}")
  end

  def clear_queue
    @queue = []
  end

  def format_song_name(song)
    song.sub(/\.NA/, '')
  end

  def playing_from_queue?
    source === 'queue'
  end
end
