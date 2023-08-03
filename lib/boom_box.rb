require 'byebug'
require 'discordrb'
require 'dotenv/load'
require 'yt_dlp'
require 'fileutils'

class BoomBox
  attr_accessor :queue, :currently_playing

  def initialize
    @queue = []
    @currently_playing = ''
  end

  def add_song(url)
    raise StandardError.new "This is a playlist" if url.include?("list=")

    song = download_song_file(url)
    @queue << song
  end

  def download_song_file(url)
    song = YtDlp::Video.new(url, extract_audio: true).download
    song = "#{File.basename(song, File.extname(song))}.opus"
    FileUtils.mv(song, "lib/songs/")

    return song
  end

  def remove_song(idx)
    @queue.reject! { |ele| ele == @queue[idx] }
  end

  def delete_song_file(song)
    File.delete("lib/songs/#{song}") if File.exist?("lib/songs/#{song}")
  end

  def clear_queue
    @queue = []
  end

  def format_song_name(song)
    song.sub(/ \[.*\]\.opus/, '')
  end
end
