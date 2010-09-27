module YouTubeModel # :nodoc:
  module Helpers
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
      settings = {
        :border => '0',
        :rel => '0',
        :color1 => '0x666666',
        :color2 => '0x666666',
        :hl => 'en',
        :width => 425,
        :height => 373
      }.merge(options)
    
      params = settings.to_query
      %Q(
    <object width="#{settings[:width]}" height="#{settings[:height]}">
        <param name="movie" value="http://www.youtube.com/v/#{video.id}&#{params}"></param>
        <param name="wmode" value="transparent"></param>
        <embed src="http://www.youtube.com/v/#{video.id}&#{params}" type="application/x-shockwave-flash" wmode="transparent" width="#{settings[:width]}" height="#{settings[:height]}"></embed>
    </object>
      )
    end
  
    # Returns a link to the authentication Google page.
    # 
    # Pass the new_<your-controller>_url or whatever url you use to the Upload's step 1
    #
    # Example:
    #   <%= link_to 'Upload a new video', youtube_auth_url(new_videos_url) %>
    #
    def youtube_auth_url(next_url)
      params = {
        :session => YouTubeModel::Base::YT_CONFIG['auth_sub']['session'],
        :secure => YouTubeModel::Base::YT_CONFIG['auth_sub']['secure'],
        :scope => 'http://gdata.youtube.com',
        :next => next_url
      }
      "https://www.google.com/accounts/AuthSubRequest?#{params.to_query}"
    end 
  end
end