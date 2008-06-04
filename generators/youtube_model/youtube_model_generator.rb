class YoutubeModelGenerator < Rails::Generator::NamedBase  
  def manifest
    record do |m|
      m.class_collisions class_path, "#{class_name}"
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)
      m.template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb', File.join('test/unit', class_path, "#{file_name}_test.rb")
    end
  end
  
  protected
  
  def banner
    "Usage: #{$0} youtube_model ModelName"
  end
end