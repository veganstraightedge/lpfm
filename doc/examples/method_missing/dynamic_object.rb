class DynamicObject
  def initialize
    @attributes = {}
  end

  def method_missing(method_name, *args)
    if method_name.to_s.end_with?('=')
      attr_name = method_name.to_s.chomp('=')
      @attributes[attr_name] = args.first
    else
      @attributes[method_name.to_s]
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    true
  end
end
