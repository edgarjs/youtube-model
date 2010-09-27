require 'builder'
      require 'ruby-debug'

      Debugger.start
      if Debugger.respond_to?(:settings)
        Debugger.settings[:autoeval] = true
        Debugger.settings[:autolist] = 1
      end

module YouTubeModel

  class Collection < Array
    attr_accessor :start_index, :items_per_page, :total_results

    def initialize(klass, parsed_xml)
      self.start_index = parsed_xml['startIndex'].to_i
      self.items_per_page = parsed_xml['itemsPerPage'].to_i
      self.total_results = parsed_xml['totalResults'].to_i
      super([parsed_xml['entry']].flatten.map{|video| klass.new(video)})
    end
  end

  module Factory

    # create a standard request api class method which instanciate some video resource
    def create_finder(name, collection = :collection, &url)
      (class << self; self; end).send(:define_method, name) do |*args|
        parsed_xml = extend_attributes(request(url.call(*args)))
        if collection.to_s == 'collection'
          Collection.new self, parsed_xml
        else
          new parsed_xml
        end
      end
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
      options[:headers] = request_headers(options[:headers] || {})
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
      h = {'Accept' => '*/*', 'GData-Version' => "2", 'X-GData-Key' => "key=#{self.const_get('YT_CONFIG')['auth_sub']['developer_key']}"}
      if accept = params.delete(:accept) and accept.to_s == 'xml'
        h.update('Accept' => 'application/atom+xml')
      end
      if content_type = params.delete(:content_type) and content_type.to_s == 'xml'
        h.update('Content-Type' => 'application/atom+xml')
      end
      if length = params.delete(:length)
        h.update('Content-Length' => length.to_s)
      end
      if token = params.delete(:auth)
        h.update('Authorization' => %Q(AuthSub token="#{token}"))
      end
      h.update(params)
    end

    # Adds some extra keys to the +attributes+ hash
    def extend_attributes(yt)
      if yt['entry']
        [yt['entry']].flatten.each { |v| refactor_xml(v) }
      else #TODO: to remove ? In witch case is this usefull ?
        refactor_xml(yt)
      end
      yt
    end

    # Renames the +id+ key to +api_id+ and leaves the simple video id on the +id+ key
    # Renames comments to comments_attr in order to avoid conflicts whith the instance method
    # Extract group and update
    def refactor_xml(attrs)
      attrs['id'] = attrs['id'].to_s.scan(/[\w-]+$/).to_s
      attrs['comments_attr'] = attrs.delete('comments') if attrs['comments']
      attrs.update attrs.delete('group') if attrs['group']
      attrs['keywords'] = attrs['keywords'].split(',').map(&:strip).map(&:downcase) if attrs['keywords']
      attrs
    end

  end

  module ClassMethods


#    def self.extended(base)
#      require 'ruby-debug'
#
#      Debugger.start
#      if Debugger.respond_to?(:settings)
#        Debugger.settings[:autoeval] = true
#        Debugger.settings[:autolist] = 1
#      end
#      debugger
#    end

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



  end
  module CRUDMethods
    def create

      data = %{--bbe873dc\r
Content-Type: application/atom+xml; charset=UTF-8

#{build_xml_entry}\r
--bbe873dc\r
Content-Type: #{file.instance_variable_get('@content_type')}
Content-Transfer-Encoding: binary

#{file.read}\r
--bbe873dc--\r\n}

      rsp= request(:method => :post,
        :url => "http://uploads.gdata.youtube.com/feeds/api/users/default/uploads",
        :data => data,
        :headers => {
          :auth => token,
          :length => data.length,
          'Slug' => File.basename(file.instance_variable_get('@original_path')),
          'Host' => 'uploads.gdata.youtube.com',
          'Connection' => 'close',
          'Content-Type' => 'multipart/related; boundary="bbe873dc"'
        })

      load_attributes_from_response(rsp)

    end

    def destroy
      rsp = request :method => :delete, :url => "users/default/uploads/#{id}", :headers => { :accept => :xml, :content_type => :xml, :auth => token }
      rsp.code == "200"
    end

    def request(*args)
      self.class.send :request, *args
    end

    def update
      xml_entry = build_xml_entry
      rsp = request :method => :put,
              :url => "users/default/uploads/#{id}",
              :data => xml_entry,
              :headers => {:accept => :xml, :content_type => :xml, :auth => token, :length => xml_entry.length }
      load_attributes_from_response(rsp)
    end

    private

    # Builds the XML content to do the POST to obtain the upload url and token.
    def build_xml_entry
      xml = Builder::XmlMarkup.new(:indent => 2)
      xml.instruct! :xml, :version => '1.0', :encoding => nil
      xml.entry :xmlns => 'http://www.w3.org/2005/Atom',
        'xmlns:media' => 'http://search.yahoo.com/mrss/',
        'xmlns:yt' => 'http://gdata.youtube.com/schemas/2007' do
        xml.media :group do
          xml.tag! 'media:title', attributes['title'], :type => 'plain'
          xml.media :description, attributes['description'], :type => 'plain'
          xml.media :category, attributes['category'], :scheme => 'http://gdata.youtube.com/schemas/2007/categories.cat'
#          xml.media :category, "ytm_#{YT_CONFIG['developer_tag']}", :scheme => 'http://gdata.youtube.com/schemas/2007/developertags.cat'
          xml.tag! 'media:keywords', attributes['keywords'].is_a?(Array) ? attributes['keywords'].join(', ') : attributes['keywords'].to_s
        end
      end
      xml.target!
    end

  end
  module InstanceMethods
    # Comments for a video.

    def comments(force=false)
      if @attributes['comments'].nil? or force == true
        load({ :comments => request(comments_attr.feedLink.href)['entry'] })
      end
      @attributes['comments']
    end

    def related_instances
      self.class.related_to(self)
    end

    # Responses videos for a video.
    def responses_to
      request(link[1].href)
    end

    def status(force=false)
      if force or not attributes['control']
        self.class.find_by_id(id, :token => token)
        control.state
      else
        control.state
      end
    end



    def request(*options)
      self.class.request(*options)
    end


    protected

    # Add extend attributes before loading xml from the API
    def load_attributes_from_response(response)
      if response['Content-Length'] != "0" && response.body.strip.size > 0
        load self.class.extend_attributes(self.class.format.decode(response.body))
      end
    end

  end

  class YouTubeModel::Base < ActiveResource::Base # :nodoc:

    YT_CONFIG = YAML.load_file("#{Rails.root}/config/video_config.yml")

    self.site = "http://gdata.youtube.com/feeds/api"
    self.timeout = 5

    extend Factory
    extend ClassMethods
    include CRUDMethods
    include InstanceMethods

    # Retrieve the top rated videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder "top_rated", :collection do |*time|
      "standardfeeds/top_rated#{query_string(:time => time.first || :all_time)}"
    end

    create_finder "uploaded_by_user", :collection do |token|
      { :url => "users/default/uploads", :headers => { :auth => token } }
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :top_favorites, :collection do |*time|
      "standardfeeds/top_favorites#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :most_viewed, :collection do |*time|
      "standardfeeds/most_viewed#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :most_recent, :collection do |*time|
      "standardfeeds/most_recent#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :most_discussed, :collection do |*time|
      "standardfeeds/most_discussed#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :most_linked, :collection do |*time|
      "standardfeeds/most_linked#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the most viewed videos for a time. Valid times are:
    # * :today (1 day)
    # * :this_week (7 days)
    # * :this_month (1 month)
    # * :all_time (default)
    create_finder :most_responded, :collection do |*time|
      "standardfeeds/most_responded#{query_string(:time => time.first || :all_time )}"
    end

    # Retrieve the recently featured videos.
    create_finder :recently_featured, :collection do
      "standardfeeds/recently_featured"
    end


    # Retrieve the videos watchables on mobile.
    create_finder :watch_on_mobile, :collection do
      "standardfeeds/watch_on_mobile"
    end

    # Finds videos by categories or keywords.
    #
    # Capitalize words if you refer to a category.
    #
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_category_and_tag('cats|dogs', '-rats', 'Comedy')
    create_finder :find_by_category_and_tag, :collection do |*tags_and_cats|
      "videos/-/#{tags_and_cats.map{ |t| CGI::escape(t) }.join('/')}"
    end

    # Finds videos by tags (keywords).
    #
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_tag('cats|dogs', '-rats')
    create_finder :find_by_tag, :collection do |*tags|
      url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fkeywords.cat%7D"
      keywords = tags.map{ |t| CGI::escape(t) }.join('/')
      "#{url}#{keywords}"
    end

    # Finds videos by tags (keywords).
    #
    # You can use the operators +NOT+(-) and +OR+(|). For example:
    #   find_by_tag('cats|dogs', '-rats')
    create_finder :find_by_category, :collection do |*categories|
      url = "videos/-/%7Bhttp%3A%2F%2Fgdata.youtube.com%2Fschemas%2F2007%2Fcategories.cat%7D"
      keywords = categories.map{ |c| CGI::escape(c) }.join('/')
      "#{url}#{keywords}"
    end

    # Find uploaded videos by a user.
    create_finder :uploaded_by, :collection do |username|
      "users/#{username}/uploads"
    end

    # Related videos for a video.
    create_finder :related_to, :collection do |inst|
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
    create_finder :find, :collection do |*args|
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
    create_finder :find_by_id, :singular do |*params|
      options = params.extract_options!.symbolize_keys!
      video_id = params.first
      if options[:token]
        { :url => "users/default/uploads/#{video_id}", :headers => { :accept => :xml, :auth => options[:token] } }
      else
        "videos/#{video_id}"
      end
    end

#   # Find status of video uploaded by a user.
#    def status
#      request :url => "users/default/uploads/#{id}", :headers => {:auth => token}
#    end

  end
end