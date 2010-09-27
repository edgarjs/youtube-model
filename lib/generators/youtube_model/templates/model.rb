class <%= class_name %> < YouTubeModel::Base #inherits from ActiveResource::Base
  schema do
    attribute :title, :string
    attribute :description, :string
    attribute :keywords, :string
    attribute :category, :string
    attribute :file, :string
    attribute :token, :string
  end

  validates_presence_of :title
  validates_presence_of :file, :if => Proc.new{|<%=singular_name%>| <%=singular_name%>.new? }

end