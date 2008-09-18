class YoutubeModelGenerator < Rails::Generator::NamedBase  
  def manifest
    record do |m|
      m.class_collisions class_path, class_name
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
      m.file 'config.yml', File.join('config', "#{file_name}_config.yml")
      m.template 'initializer.rb', File.join('config/initializers', "#{file_name}_initalizer.rb")
    end
  end
  
  protected
  
  def banner
    "Usage: #{$0} youtube_model ModelName"
  end
end