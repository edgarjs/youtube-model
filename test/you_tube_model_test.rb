require 'test_helper'

class Video < YouTubeModel::Base
  schema do
    attribute :title, :string
    attribute :description, :string
    attribute :keywords, :string
    attribute :category, :string
    attribute :file, :string
    attribute :token, :string
  end

  self.default_youtube_options= {:itemPerPage => 10}

  validates_presence_of :title
  validates_presence_of :file, :if => Proc.new{|video| video.new? }
end

class YouTubeModelTest < Test::Unit::TestCase

  def setup
    @video = Video.new
    @token = 'test'
  end

  def teardown
    unregister_uri
  end

  def test_struct
    assert_equal(Video.default_youtube_options, {:itemPerPage => 10})
    assert Video.respond_to?(:create_finder)
    assert Video.respond_to?(:top_rated), "custom finder is not associated to the YouTubeModel::Base"
  end

  def test_collection_finders
    register_uri :get, "http://gdata.youtube.com/feeds/api/standardfeeds/top_rated?itemPerPage=10&startIndex=5&time=all_time", 'videos'
    @videos = Video.top_rated(:startIndex => 5)
    assert @videos.is_a?(YouTubeModel::Collection)
    assert @videos.first.is_a?(Video)
    assert_equal "dMH0bHeiRNg", @videos.first.id
  end
  def test_collection_finder_with_session_token_passed
    register_uri :get, "http://gdata.youtube.com/feeds/api/users/default/uploads?itemPerPage=10", 'videos'
    @videos = Video.uploaded_by_user(:token => 'test_token')
    assert @videos.all?{|v| v.token == 'test_token'}
  end
  def test_singular_finder
    register_uri :get, "http://gdata.youtube.com/feeds/api/videos/dMH0bHeiRNg", 'video'
    @video = Video.find_by_id("dMH0bHeiRNg")
    assert @video.is_a?(Video)
    assert_equal "4fDTbIIlggE", @video.id
    assert_equal "test", @video.description
    assert_equal 'io', @video.keywords
    assert_equal "Film", @video.category

  end


  def test_singular_finder_with_session_token_passed
    register_uri :get, "http://gdata.youtube.com/feeds/api/users/default/uploads/dMH0bHeiRNg", 'video'
    @video = Video.find_by_id("dMH0bHeiRNg", :token => 'test_token')
    assert @video.is_a?(Video)
    assert_equal "test_token", @video.token
  end

  def test_instance_method_comments
    register_uri :get, /gdata.youtube.com/, 'comments'
    video = Video.new(:id => 'test').load({:comments_attr => { :feedLink => {:href => 'http://gdata.youtube.com/feeds/api/videos/ZTUVgYoeN_b/comments' } } } )
    comments = video.comments
    assert comments.is_a?(Array)
    assert_equal "im 16 and have new training vids up if anyone needs help comment:)", video.comments.first.content
  end

  def create
    register_uri :post, /uploads.gdata.youtube.com/, 'video'
    @video = Video.create(:title => "test",:file => fixture_file_upload('files/sample_iTunes.mov', 'application/octet-stream'))
    assert_equal @video.id, "4fDTbIIlggE"
    assert @video.is_a?(Video)
  end

  def test_update
    @video = Video.new(:id => "dMH0bHeiRNg", :title => 'test', :token => 'io')
    register_uri :put, "http://gdata.youtube.com/feeds/api/users/default/uploads/dMH0bHeiRNg", 'video'
    assert_equal true, @video.save
    assert_equal '4fDTbIIlggE', @video.id
    assert_equal "test io", @video.title
  end

# Don't handle this kind of exception, we want to be alerted when they occurs
#  def test_youtube_return_error_on_crud_method
#    FakeWeb.register_uri(:put, "http://gdata.youtube.com/feeds/api/users/default/uploads/dMH0bHeiRNg", :body => "Bad request", :status => ["404", "Bad request"])
#    @video = Video.new(:id => "dMH0bHeiRNg", :title => 'test', :token => 'io')
#    assert_equal false, @video.save
#    assert_match /Bad request/, @video.errors.to_s
#  end

  def test_delete

  end

  def test_validation_on_create
   video = Video.new()
   assert_equal false, video.valid?
   assert_equal "can't be blank", video.errors[:title].to_s
   assert_equal "can't be blank", video.errors[:file].to_s
   assert_equal 2, video.errors.size
  end

  def test_validation_on_update
    video = Video.new(:id => 'test')
    assert_equal false, video.valid?
    assert_equal "can't be blank", video.errors[:title].to_s
    assert_equal 1, video.errors.size
  end

end