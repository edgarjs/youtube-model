require 'you_tube_model'
require 'you_tube_helpers'

ActiveResource::Base.send(:include, YouTubeModel)
ActionView::Base.send(:include, YouTubeModel::Helpers)