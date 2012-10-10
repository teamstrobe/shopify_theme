require 'httparty'
module ShopifyTheme
  include HTTParty

  NOOPParser = Proc.new {|data, format| {} }

  def self.asset_list
    # HTTParty parser chokes on assest listing, have it noop
    # and then use a rel JSON parser.
    response = shopify.get(path, :parser => NOOPParser)
    assets = JSON.parse(response.body)["assets"].collect {|a| a['key'] }
    # Remove any .css files if a .css.liquid file exists
    assets.reject{|a| assets.include?("#{a}.liquid") }
  end

  def self.get_asset(asset)
    response = shopify.get(path, :query =>{:asset => {:key => asset}}, :parser => NOOPParser)
    # HTTParty json parsing is broken?
    JSON.parse(response.body)["asset"]
  end

  def self.send_asset(data, env)
    shopify(env).put(path(env), :body =>{:asset => data})
  end

  def self.delete_asset(asset)
    shopify.delete(path, :body =>{:asset => {:key => asset}})
  end

  def self.config
    @config ||= YAML.load(File.read('config.yml'))
  end

  def self.path(env)
    @path ||= config[:theme_id] ? "/admin/themes/#{config[:"#{env}"][:theme_id]}/assets.json" : "/admin/assets.json" 
  end

  def self.ignore_files
    @ignore_files ||= (config[:ignore_files] || []).compact.collect { |r| Regexp.new(r) }
  end

  def self.is_binary_data?(string)
    if string.respond_to?(:encoding)
      string.encoding == "US-ASCII"
    else
      ( string.count( "^ -~", "^\r\n" ).fdiv(string.size) > 0.3 || string.index( "\x00" ) ) unless string.empty?
    end
  end

  private
  def self.shopify(env)
    basic_auth config[:"#{env}"][:api_key], config[:"#{env}"][:password]
    base_uri "http://#{config[:"#{env}"][:store]}"
    ShopifyTheme
  end
end
