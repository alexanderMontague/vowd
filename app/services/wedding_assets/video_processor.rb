require "open3"

module WeddingAssets
  # Transcodes invitation videos to a compact H.264 MP4 and extracts the first
  # frame as a WebP poster (stored as the asset thumbnail).
  class VideoProcessor
    MAX_WIDTH = 1280
    CRF = 28
    PRESET = "medium"
    AUDIO_BITRATE = "96k"
    OUTPUT_CONTENT_TYPE = "video/mp4".freeze
    FFMPEG_BIN = ENV.fetch("FFMPEG_PATH", "ffmpeg").freeze

    Result = Struct.new(:io, :thumbnail_io, :content_type, :byte_size, :thumbnail_content_type, keyword_init: true) do
      def close
        io.close if io.respond_to?(:close) && !io.closed?
        thumbnail_io.close if thumbnail_io.respond_to?(:close) && !thumbnail_io.closed?
      end
    end

    def self.call(uploaded_file:)
      new(uploaded_file).call
    end

    def initialize(uploaded_file)
      @uploaded_file = uploaded_file
      @temp_paths = []
    end

    def call
      ensure_ffmpeg!
      input_path = materialize_input
      poster_path = extract_poster(input_path)
      video_path = transcode(input_path)
      poster = ImageCompressor.from_path(poster_path)

      # Full-size WebP as the public poster; discard the tiny admin crop.
      poster.thumbnail_io.close if poster.thumbnail_io.respond_to?(:close)

      Result.new(
        io: File.open(video_path, "rb"),
        thumbnail_io: poster.io,
        content_type: OUTPUT_CONTENT_TYPE,
        byte_size: File.size(video_path),
        thumbnail_content_type: ImageCompressor::OUTPUT_CONTENT_TYPE
      )
    end

    private

    def ensure_ffmpeg!
      _stdout, status = Open3.capture2(FFMPEG_BIN, "-version")
      return if status.success?

      raise ArgumentError, "Video processing requires ffmpeg."
    rescue Errno::ENOENT
      raise ArgumentError, "Video processing requires ffmpeg."
    end

    def materialize_input
      tempfile = @uploaded_file.tempfile
      tempfile.rewind if tempfile.respond_to?(:rewind)
      extension = File.extname(tempfile.path).presence || extension_for_content_type
      track_temp(File.join(Dir.tmpdir, "wedding-video-in-#{SecureRandom.hex(8)}#{extension}")).tap do |path|
        FileUtils.cp(tempfile.path, path)
      end
    end

    def extract_poster(input_path)
      output = track_temp(File.join(Dir.tmpdir, "wedding-video-poster-#{SecureRandom.hex(8)}.jpg"))
      run_ffmpeg!(
        "-y",
        "-ss", "0",
        "-i", input_path,
        "-frames:v", "1",
        "-q:v", "2",
        output
      )
      output
    end

    def transcode(input_path)
      output = track_temp(File.join(Dir.tmpdir, "wedding-video-out-#{SecureRandom.hex(8)}.mp4"))
      run_ffmpeg!(
        "-y",
        "-i", input_path,
        "-c:v", "libx264",
        "-crf", CRF.to_s,
        "-preset", PRESET,
        "-vf", "scale='min(#{MAX_WIDTH},iw)':-2",
        "-c:a", "aac",
        "-b:a", AUDIO_BITRATE,
        "-movflags", "+faststart",
        "-pix_fmt", "yuv420p",
        output
      )
      output
    end

    def run_ffmpeg!(*args)
      _stdout, stderr, status = Open3.capture3(FFMPEG_BIN, *args)
      return if status.success?

      Rails.logger.error("ffmpeg failed: #{stderr.to_s.truncate(500)}")
      raise ArgumentError, "Could not process video. Please try a different file."
    end

    def extension_for_content_type
      case @uploaded_file.content_type.to_s
      when "video/webm" then ".webm"
      when "video/quicktime" then ".mov"
      else ".mp4"
      end
    end

    def track_temp(path)
      @temp_paths << path
      path
    end
  end
end
