class YoutubeModelGenerator < Rails::Generators::NamedBase

  desc "Generate youtube_model files, Usage: rails g youtube_model ModelName"

  source_root File.expand_path('../templates', __FILE__)

  check_class_collision

  def manifest
    template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
    template 'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
    template 'config.yml', File.join('config', "#{file_name}_config.yml")
    template 'initializer.rb', File.join('config/initializers', "#{file_name}_initalizer.rb")
  end
  
end