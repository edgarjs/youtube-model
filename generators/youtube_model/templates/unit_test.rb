require File.dirname(__FILE__) + '/../test_helper'

class <%= class_name %>Test < Test::Unit::TestCase
  def setup
    @v = <%= class_name %>.uploaded_by('rumil')
  end
  
  def test_this_plugin
    assert('rumil', @v.author.name)
    assert_match(/Videos related to.+/,
      <%= class_name %>.related_to(@v.videos.first).title)
    assert_match(/Videos responses to.+/,
      <%= class_name %>.responses_to(@v.videos.first).title)
    assert_equal('YouTube Videos matching query: ruby+on+rails',
      <%= class_name %>.find('ruby on rails').title)
    assert_equal('Top Rated', <%= class_name %>.top_rated(:today).title)
  end
end