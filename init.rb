require 'you_tube_model'
require 'you_tube_helpers'

ActiveResource::Base.send(:include, Mimbles::YouTubeModel)
ActionView::Base.send(:include, Mimbles::YouTubeModel::Helpers)