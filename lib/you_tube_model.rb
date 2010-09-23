module YouTubeModel # :nodoc:


  # Call this method to make an ActiveResource model ready to roll with YouTube
  def acts_as_youtube_model
    self.site = "http://gdata.youtube.com/feeds/api"
    self.timeout = 5

    extend SingletonMethods
    include InstanceMethods
  end

  module ClassMethods
    # create a standard request api class method which instanciate some video resource
    def create_method(name, collection = :collection, &url)
      define_method name do |*args|
        instanciate collection do
          request(url.call(*args))
        end
      end
    end
  end

  class Collection < Array
    attr_accessor :start_index, :items_per_page, :total_results

    def initialize(klass, &block)
      response = block.call
      self.start_index = response['startIndex'].to_i
      self.items_per_page = response['itemsPerPage'].to_i
      self.total_results = response['totalResults'].to_i
      super([response['entry']].flatten.map{|video| klass.new.load(video)})
    end
  end

  module InstanceMethods
    # Comments for a video.

    def request(*options)
      self.class.request(*options)
    end

    def comments(force=false)
      if @attributes['comments'].nil? or force == true
        load({ :comments => request(comments_attr.feedLink.href)['entry'] })
      else
        @attributes['comments']
      end
    end

    def related_instances
      self.class.related_to(self)
    end

    # Responses videos for a video.
    def responses_to
      self.class.request(link[1].href)
    end

  end

  module SingletonMethods
    extend ClassMethods

    #Instanciate video by
    def instanciate(type='collection', &block)
      col = Collection.new self do
        extend_attributes(block.call)
      end
      type.to_s == 'collection' ? col : col.first
    end


    # Retrieve the top rated videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method "top_rated", :collection do |*time|
      "standardfeeds/top_rated#{query_string(:time => time.first || :all_time)}"
    end

    create_method "uploaded_by_user", :collection do |token|
      { :url => "users/default/uploads", :headers => { :auth => token } }
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :top_favorites, :collection do |*time|
      "standardfeeds/top_favorites#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :most_viewed, :collection do |*time|
      "standardfeeds/most_viewed#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :most_recent, :collection do |*time|
      "standardfeeds/most_recent#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :most_discussed, :collection do |*time|
      "standardfeeds/most_discussed#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :most_linked, :collection do |*time|
      "standardfeeds/most_linked#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_method :most_responded, :collection do |*time|
      "standardfeeds/most_responded#{query_string(:time => time.first || :all_time )}"
    end
      
    # Retrieve the recently featured videos.
    create_method :recently_featured, :collection do
      "standardfeeds/recently_featured"
    end


    # Retrieve the videos watchables on mobile.
    create_method :watch_on_mobile, :collection do
      "standardfeeds/watch_on_mobile"
    end

    # Finds videos by categories or keywords.
    # 
    # Capitalize words if you refer to a category.
    # 
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_category_and_tag('cats|dogs', '-rats', 'Comedy')
    create_method :find_by_category_and_tag, :collection do |*tags_and_cats|
      "videos/-/#{tags_and_cats.map{ |t| CGI::escape(t) }.join('/')}"
    end

    # Finds videos by tags (keywords).
    # 
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_tag('cats|dogs', '-rats')
    create_method :find_by_tag, :collection do |*tags|
      url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fkeywords.cat%7D"
      keywords = tags.map{ |t| CGI::escape(t) }.join('/')
      "#{url}#{keywords}"
    end

    # Finds videos by tags (keywords).
    # 
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_tag('cats|dogs', '-rats')
    create_method :find_by_category, :collection do |*categories|
      url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fcategories.cat%7D"
      keywords = categories.map{ |c| CGI::escape(c) }.join('/')
      "#{url}#{keywords}"
    end

    # Find uploaded videos by a user.
    create_method :uploaded_by, :collection do |username|
      "users/#{username}/uploads"
    end

    # Related videos for a video.
    create_method :related_to, :collection do |inst|
      inst.link[2].href
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
    create_method :find, :collection do |*args|
      options = (args.size == 2) ? args.last : {}
      options[:vq] = args.first
      options[:orderby] ||= :relevance
      options.delete(:alt)
      params = Hash[*options.stringify_keys.collect{ |k, v|
          [k.dasherize, v] }.flatten
      ]
      "videos#{query_string(params)}"
    end

#    def find(query, options = {})
#      options[:vq] = query
#      options[:orderby] ||= :relevance
#      options.delete(:alt)
#      params = Hash[*options.stringify_keys.collect{ |k, v|
#          [k.dasherize, v] }.flatten
#      ]
#      request("videos#{query_string(params)}")
#    end

    # Search for a specific video by its ID.
    #   http://www.youtube.com/watch?v=JMDcOViViNY
    # Here the id is: *JMDcOViViNY* NOTE: this method returns the video itself,
    # no need to call @yt.video
    create_method :find_by_id, :singular do |id|
      "videos/?q=#{id}"
    end
    
    # Fetchs few YouTube categories
    def video_categories
      [["Film & Animation", "Film"], ["Autos & Vehicles", "Autos"], ["Music", "Music"], ["Pets & Animals", "Animals"], ["Sports", "Sports"],
      ["Travel & Events", "Travel"], ["News & Politics", "News"], ["Howto & Style", "Howto"], ["Gaming", "Games"], ["Comedy", "Comedy"], 
      ["People & Blogs", "People"], ["Entertainment", "Entertainment"], ["Education", "Education"], ["Nonprofits & Activism", "Nonprofit"], 
      ["Science & Technology", "Tech"]]
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
    


    def upload_video(meta)
      xml_entry = build_xml_entry(meta)
      data = %{--bbe873dc\r
Content-Type: application/atom+xml; charset=UTF-8

#{xml_entry}\r
--bbe873dc\r
Content-Type: #{meta[:file].content_type}
Content-Transfer-Encoding: binary

#{meta[:file].read}\r
--bbe873dc--\r\n}

      response = request(:method => :post,
        :url => "http://uploads.gdata.youtube.com/feeds/api/users/default/uploads",
        :data => data,
        :headers => {
          :auth => meta[:auth_sub],
          :length => data.length,
          'GData-Version' => "2",
          'Slug' => meta[:file].original_filename,
          'Host' => 'uploads.gdata.youtube.com',
          'Connection' => 'close',
          'Content-Type' => 'multipart/related; boundary="bbe873dc"'
        })
      debugger


      upload = {}
      (Hpricot.XML(response.body)/:response).each do |elm|
        upload[:url] = "#{(elm/:url).text}?#{{:nexturl => meta[:nexturl]}.to_query}"
        upload[:token] = (elm/:token).text
      end if response.code == "200"
      upload[:code] = response.code

      upload

    end
    
    def delete_video(video_id, token)
      request :method => :delete, :url => "users/default/uploads/#{video_id}", :headers => { :accept => :xml, :auth => token }
    end
    
    def update_video(video_id, token, video_params)
      xml_entry = build_xml_entry(video_params)
      request :method => :put,
              :url => "users/default/uploads/#{video_id}",
              :data => xml_entry,
              :headers => {:accept => :xml, :auth => token, :length => xml_entry.length }
    end
    
    # Find status of video uploaded by a user.
    def video_status(token, video_id)
      request :url => "users/default/uploads/#{video_id}", :headers => {:auth => token}
    end
    
    def videos_with_user_as_default(token)
      request :url => "users/default/uploads", :headers => {:auth => token}
    end

    # Request Google API
    # Receive a simple url String as argument for get request without authentication
    # Receive an option Hash width the keys :
    #   - :method (optional default get),
    #   - :url    (required),
    #   - :header (optional default {'Accept' => '*/*'},
    #   - :data   (optional)

    def request(options)
      options = { :url => options } if options.is_a?(String)
      options[:method] ||= :get
      options[:url] = options[:url] =~ /\Ahttp:/ ? options[:url] : "#{self.prefix}#{options[:url]}"
      options[:headers] = request_headers(options[:headers])
      if [:post,:put].include? options[:method]
        connection.send(options[:method], options[:url], options[:data].to_s, options[:headers])
      else
        connection.send(options[:method], options[:url], options[:headers])
      end
    end

    # Build the expected API request headers
    # Receive as parameter a hash of short-key for common header, plus somme custom other pair
    #   - :auth => token,
    #   - :length => content_size,
    #   - :accept => [:all, :xml]
    def request_headers(params={})
      h = {'Accept' => '*/*'}
      if accept = params.delete(:accept) and accept.to_s == 'xml'
        h.update('Accept' => 'application/atom+xml')
      end
      if length = params.delete(:length)
        h.update('Content-Length' => length.to_s)
      end
      if token = params.delete(:auth)
        h.update('Authorization' => %Q(AuthSub token="#{token}"), 'X-GData-Key' => "key=#{YT_CONFIG['auth_sub']['developer_key']}")
      end
      h.update(params)
    end


    private
  
    # Adds some extra keys to the +attributes+ hash
    def extend_attributes(yt)
      unless yt['entry'].nil?
        [yt['entry']].flatten.each { |v| scan_id(v) }
      else #TODO: to remove ? In witch case is this usefull ?
        scan_id(yt)
      end
      yt
    end
    
    # Renames the +id+ key to +api_id+ and leaves the simple video id on the +id+ key
    # Plus rename comments to comments_attr in order to avoid conflicts whith the instance method
    def scan_id(attrs)
      attrs['api_id'] = attrs['id']
      attrs['id'] = attrs['api_id'].scan(/[\w-]+$/).to_s
      attrs['comments_attr'] = attrs.delete('comments') if attrs['comments']
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
          xml.tag! 'media:title', attrs[:title], :type => 'plain'
          xml.media :description, attrs[:content], :type => 'plain'
          xml.media :category, attrs[:category], :scheme => 'http://gdata.youtube.com/schemas/2007/categories.cat'
#          xml.media :category, "ytm_#{YT_CONFIG['developer_tag']}", :scheme => 'http://gdata.youtube.com/schemas/2007/developertags.cat'
          xml.tag! 'media:keywords', attrs[:keywords]
        end
      end
      xml.target!
    end
  end
end