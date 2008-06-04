module Mimbles # :nodoc:
  module YouTubeModel # :nodoc:
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      # Call this method to make an ActiveResource model ready to roll with
      # YouTube
      def acts_as_youtube_model
        self.site = "http://gdata.youtube.com/feeds/api"
        extend Mimbles::YouTubeModel::SingletonMethods
        include Mimbles::YouTubeModel::InstanceMethods
      end
    end
    
    module InstanceMethods
      # Just another name for +entry+
      def videos
        self.entry if respond_to?(:entry)
      end
      alias video videos
    end
    
    module SingletonMethods
      # Retrieve the top rated videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def top_rated(time = :all_time)
        request("standardfeeds/top_rated#{query_string(:time => time)}")
      end
      
      # Retrieve the top favorited videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def top_favorites(time = :all_time)
        request("standardfeeds/top_favorites#{query_string(:time => time)}")
      end
      
      # Retrieve the most viewed videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def most_viewed(time = :all_time)
        request("standardfeeds/most_viewed#{query_string(:time => time)}")
      end
      
      # Retrieve the most recent videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def most_recent(time = :all_time)
        request("standardfeeds/most_recent#{query_string(:time => time)}")
      end
      
      # Retrieve the most discussed videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def most_discussed(time = :all_time)
        request("standardfeeds/most_discussed#{query_string(:time => time)}")
      end
      
      # Retrieve the most linked videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def most_linked(time = :all_time)
        request("standardfeeds/most_linked#{query_string(:time => time)}")
      end
      
      # Retrieve the most responded videos for a time. Valid times are:
      # * :today (1 day)
      # * :this_week (7 days)
      # * :this_month (1 month)
      # * :all_time (default)
      def most_responded(time = :all_time)
        request("standardfeeds/most_responded#{query_string(:time => time)}")
      end
      
      # Retrieve the recently featured videos.
      def recently_featured
        request("standardfeeds/recently_featured")
      end
      
      # Retrieve the videos watchables on mobile.
      def watch_on_mobile
        request("standardfeeds/watch_on_mobile")
      end
      
      # Finds videos by categories or keywords.
      # 
      # Capitalize words if you refer to a category.
      # 
      # You can use the operators +NOT+(-) and +OR+(|). For example:
      #   find_by_category_and_tag('cats|dogs', '-rats', 'Comedy')
      def find_by_category_and_tag(*tags_and_cats)
        request("videos/-/#{tags_and_cats.map{ |t| CGI::escape(t) }.join('/')}")
      end
      
      # Finds videos by tags (keywords).
      # 
      # You can use the operators +NOT+(-) and +OR+(|). For example:
      #   find_by_tag('cats|dogs', '-rats')
      def find_by_tag(*tags)
        url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fkeywords.cat%7D"
        keywords = tags.map{ |t| CGI::escape(t) }.join('/')
        request("#{url}#{keywords}")
      end
      
      # Finds videos by tags (keywords).
      # 
      # You can use the operators +NOT+(-) and +OR+(|). For example:
      #   find_by_tag('cats|dogs', '-rats')
      def find_by_category(*categories)
        url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fcategories.cat%7D"
        keywords = categories.map{ |c| CGI::escape(c) }.join('/')
        request("#{url}#{keywords}")
      end
  
      # Find uploaded videos by a user.
      def uploaded_by(username)
        request("users/#{username}/uploads")
      end
  
      # Comments for a video.
      def comments_for(video)
        request(video.comments.feedLink.href)
      end
  
      # Related videos for a video.
      def related_to(video)
        request(video.link[2].href)
      end
  
      # Responses videos for a video.
      def responses_to(video)
        request(video.link[1].href)
      end
  
      # Find a video through a search query.
      # Options are:
      # * :orderby (:relevance, :published, :viewCount, :rating)
      # * :start_index
      # * :max_results
      # * :author
      # * :lr
      # * :racy (:include, :exclude)
      # * :restriction
      # 
      # See options details at {YouTube API}[http://code.google.com/apis/youtube/developers_guide_protocol.html#Searching_for_Videos]
      #   
      # Note: +alt+ option is still in researching because it causes some errors.
      def find(query, options = {})
        options[:vq] = CGI::escape(query)
        options.delete(:alt) # causes some errors
        params = {}
        options.each{ |k, v| params[k.to_s.dasherize] = v.to_s }
        request("videos#{query_string(params)}")
      end

      # Search for a specific video by its ID.
      #   http://www.youtube.com/watch?v=JMDcOViViNY
      # Here the id is: *JMDcOViViNY*
      # NOTE: this method returns the video itself, no need to call @yt.video
      def find_by_id(id)
        request("videos/#{id}")
      end
      
      protected
      
      # Loads a response into a new Object of this class
      def request(url)
        url = "#{self.prefix}#{url}" unless url =~ /\Ahttp:/
        new.load(connection.get(url))
      end
    end
  end
end