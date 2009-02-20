require 'hpricot'

module YouTubeModel # :nodoc:
  def self.included(base)
    base.extend ClassMethods
  end
    
  module ClassMethods
    # Call this method to make an ActiveResource model ready to roll with YouTube
    def acts_as_youtube_model
      self.site = "http://gdata.youtube.com/feeds/api"
      self.timeout = 5
        
      extend YouTubeModel::SingletonMethods
      include YouTubeModel::InstanceMethods
    end
  end
    
  module InstanceMethods
    # Returns an array of +entry+, or an empty array when there's no such +entry+
    def videos
      if respond_to?(:entry)
        entry.is_a?(Array) ? entry : [entry]
      else
        []
      end
    end
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
    
		def auth_token(user, pass, client_id = 'youtube_g')
			require "net/https"
			http = Net::HTTP.new("www.google.com", 443)
			http.use_ssl = true
			body = "Email=#{CGI::escape user}&Passwd=#{CGI::escape pass}&service=youtube&source=#{CGI::escape client_id}"
			response = http.post("/youtube/accounts/ClientLogin", body, "Content-Type" => "application/x-www-form-urlencoded")
			raise Exception, response.body[/Error=(.+)/,1] if response.code.to_i != 200
			auth_token = response.body[/Auth=(.+)/, 1]
			auth_token
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
  
    # Find a video through a search query. Options are:
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
      options[:vq] = query
      options[:orderby] ||= :relevance
      options.delete(:alt)
      params = Hash[*options.stringify_keys.collect{ |k, v|
          [k.dasherize, v] }.flatten
      ]
      request("videos#{query_string(params)}")
    end

    # Search for a specific video by its ID.
    #   http://www.youtube.com/watch?v=JMDcOViViNY
    # Here the id is: *JMDcOViViNY* NOTE: this method returns the video itself,
    # no need to call @yt.video
    def find_by_id(id)
      request("videos/#{id}")
    end
    
    # Fetchs all YouTube categories
    def categories
      connection.get('/schemas/2007/categories.cat')['category']
    end
    
    # Returns an array with only the +label+ and +term+ attributes of categories.
    def categories_collection
      categories.collect { |cat|
        [cat['label'], cat['term']]
      }
    end
    
    # Sends a POST to YouTube to get the upload url and token.
    # 
    # Receives a hash with the following keys:
    # * <tt>:title</tt> Title of the video.
    # * <tt>:description</tt> Description of the video.
    # * <tt>:category</tt> Category of the video.
    # * <tt>:keywords</tt> Keywords for the video.
    # * <tt>:auth_sub</tt> Authentication token.
    # * <tt>:nexturl</tt> Url to redirect after the video has been uploaded. Leave it nil to go to http://www.youtube.com/my_videos
    # 
    # Returns a hash with the keys:
    # * <tt>:url</tt> url for upload the video to.
    # * <tt>:token</tt> token hash necessary to upload.
    # * <tt>:code</tt> response code of the POST.
    def get_upload_url(meta)
      xml_entry = build_xml_entry(meta)
      headers = {
        'Authorization' => %Q(GoogleLogin auth="#{meta[:auth_sub]}"),
        'X-GData-Client' => YT_CONFIG['auth_sub']['client_key'],
        'X-GData-Key' => "key=#{YT_CONFIG['auth_sub']['developer_key']}",
        'Content-Length' => xml_entry.length.to_s,
        'Content-Type' => "application/atom+xml; charset=UTF-8"
      }
      response = connection.post('/action/GetUploadToken', xml_entry, headers)
      meta[:nexturl] ||= 'http://www.youtube.com/my_videos'
      upload = {}
      (Hpricot.XML(response.body)/:response).each do |elm|
        upload[:url] = "#{(elm/:url).text}?#{{:nexturl => meta[:nexturl]}.to_query}"
        upload[:token] = (elm/:token).text
      end if response.code == "200"
      upload[:code] = response.code
      
      upload
    end
    
    def destroy(meta)
      headers = {
        'Content-Type' => "application/atom+xml",
        'Authorization' => %Q(GoogleLogin token="#{meta[:auth_sub]}"),
        'X-GData-Client' => YT_CONFIG['auth_sub']['client_key'],
        'X-GData-Key' => "key=#{YT_CONFIG['auth_sub']['developer_key']}",
      }
      require 'rest_client'
      RestClient.delete("http://gdata.youtube.com/feeds/api/users/#{meta[:user_id]}/uploads/#{meta[:video_id]}", headers)
    end
      
    protected
      
    # Loads a response into a new Object of this class
    def request(url)
      url = "#{self.prefix}#{url}" unless url =~ /\Ahttp:/
      new.load(extend_attributes(connection.get(url, 'Accept' => '*/*')))
    end
    
    private
  
    # Adds some extra keys to the +attributes+ hash
    def extend_attributes(yt)
      unless yt['entry'].nil?
        (yt['entry'].is_a?(Array) ? yt['entry'] : [yt['entry']]).each { |v| scan_id(v) }
      else
        scan_id(yt)
      end
      yt
    end
    
    # Renames the +id+ key to +api_id+ and leaves the simple video id on the
    # +id+ key
    def scan_id(attrs)
      attrs['api_id'] = attrs['id']
      attrs['id'] = attrs['api_id'].scan(/[\w-]+$/).to_s
      attrs
    end
    
    # Builds the XML content to do the POST to obtain the upload url and token.
    def build_xml_entry(attrs)
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml, :version => '1.0', :encoding => nil
      xml.entry :xmlns => 'http://www.w3.org/2005/Atom',
        'xmlns:media' => 'http://search.yahoo.com/mrss/',
        'xmlns:yt' => 'http://gdata.youtube.com/schemas/2007' do
        xml.media :group do
          xml.tag! 'media:title', attrs[:title]
          xml.media :description, attrs[:description], :type => 'plain'
          xml.media :category, attrs[:category], :scheme => 'http://gdata.youtube.com/schemas/2007/categories.cat'
          xml.media :category, "ytm_#{YT_CONFIG['developer_tag']}", :scheme => 'http://gdata.youtube.com/schemas/2007/developertags.cat'
          xml.tag! 'media:keywords', attrs[:keywords]
        end
      end
      xml.target!
    end
  end
end
