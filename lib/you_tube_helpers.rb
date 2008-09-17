module Mimbles # :nodoc:
  module YouTubeModel # :nodoc:
    module Helpers
      DEFAULT_OPTIONS = {
        :border => false,
        :related => true,
        :colors => ['2b405b', '6b8ab6'],
        :language => 'en',
        :width => 425, :height => 373
      }
      
      # This helper returns the required html to embed a youtube video.
      # You can customize it with the following options:
      # * <tt>:border</tt> Specifies if the player is bordered or not.
      # * <tt>:related</tt> Specifies if the player will include related videos.
      # * <tt>:colors</tt> Array with the desired colors of the player.
      # * <tt>:language</tt> Specifies the language of the player.
      # * <tt>:width</tt> Specifies the player's width.
      # * <tt>:height</tt> Specifies the player's height.
      # 
      # Example:
      #   # in controller:
      #   @top_rated = YouTube.top_rated(:today)
      #   
      #   # in view:
      #   <% @top_rated.videos.each do |video| -%>
      #     <p><%= youtube_embed video, :border => true %></p>
      #   <% end -%>
      def youtube_embed(video, options = {})
        options = DEFAULT_OPTIONS.merge(options)
        settings = ["hl=#{options[:language]}"]
        settings << 'border=1' if options[:border]
        settings << 'rel=0' if options[:related]
        unless options[:colors][0] == DEFAULT_OPTIONS[:colors][0]
          settings << "color1=0x#{options[:colors][0]}"
          settings << "color2=0x#{options[:colors][1]}"
        end
        config = settings.join('&')
        %Q(
        <object width="#{options[:width]}" height="#{options[:height]}">
            <param name="movie" value="http://www.youtube.com/v/#{video.id}&#{config}"></param>
            <param name="wmode" value="transparent"></param>
            <embed src="http://www.youtube.com/v/#{video.id}&#{config}" type="application/x-shockwave-flash" wmode="transparent" width="#{options[:width]}" height="#{options[:height]}"></embed>
        </object>
        )
      end
    end
  end
end