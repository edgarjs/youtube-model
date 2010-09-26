require 'test_helper'

class Video < YouTubeModel::Base

end
class YouTubeTest < Test::Unit::TestCase
  def setup
    @video = Video.new
    @token = 'test'
  end

  def teardown
    unregister_uri
  end

  def test_struct
    assert Video.respond_to?(:create_finder)
    assert Video.respond_to?(:top_rated), "custom finder is not associated to the YouTubeModel::Base"
  end

  def test_collection_finders
    register_uri :get, /gdata.youtube.com/, 'videos'
    @videos = Video.top_rated
    assert @videos.is_a?(YouTubeModel::Collection)
    assert @videos.first.is_a?(Video)
    assert_equal "dMH0bHeiRNg", @videos.first.id
  end

  def test_singular_finder
    register_uri :get, /gdata.youtube.com/, 'video'
    @video = Video.find_by_id("dMH0bHeiRNg")
    assert @video.is_a?(Video)
    assert_equal "dMH0bHeiRNg", @video.id
    assert_equal "For more visit www.mightaswelldance.com", @video.description
    assert_equal ['dancing', 'comedy'], @video.keywords
    assert_equal "Comedy", @video.category
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
    assert_equal @video.id, "dMH0bHeiRNg"
    assert @video.is_a?(Video)
  end

  def test_update
    @video = Video.new(:id => "dMH0bHeiRNg", :title => 'test', :token => 'io')
    register_uri :put, "http://gdata.youtube.com/feeds/api/users/default/uploads/dMH0bHeiRNg", 'video'
    assert @video.save
    assert_equal 'dMH0bHeiRNg', @video.id
    assert_equal "Evolution of Dance - By Judson Laipply", @video.title
  end

  def test_delete

  end

  def test_validation

  end

end