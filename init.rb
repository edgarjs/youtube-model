require 'you_tube_model'
require 'you_tube_helpers'

#ActiveResource::Base.send(:extend, YouTubeModel)
ActionView::Base.send(:include, YouTubeModel::Helpers)