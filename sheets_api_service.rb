class SheetsApiService
  ROOT_URL = ENV['EXALTED_SHEETS_API_URL']
  API_TOKEN = ENV['EXALTED_API_TOKEN']

  def self.character_list(for_user_uid:)
    JSON.parse(get("users/discord/#{for_user_uid}/characters"))
  end

  def self.use_character(for_user_uid:, name:, server_uid:)
    JSON.parse(post("users/discord/#{for_user_uid}/use_character", name: name, server_uid: server_uid))
  end

  def self.unuse_character(for_user_uid:, server_uid:)
    JSON.parse(delete("users/discord/#{for_user_uid}/unuse_character", server_uid: server_uid))
  end

  def self.get_pools(pools, for_user_uid:, server_uid:)
    JSON.parse(get("characters/discord/#{for_user_uid}/server/#{server_uid}/pools", 'pools[]': pools))
  end

  def self.pay_resource(amount, resource, for_user_uid:, server_uid:)
    JSON.parse(post("characters/discord/#{for_user_uid}/server/#{server_uid}/pay", amount: amount, resource: resource))
  end

  def self.gain_resource(amount, resource, for_user_uid:, server_uid:)
    JSON.parse(post("characters/discord/#{for_user_uid}/server/#{server_uid}/gain", amount: amount, resource: resource))
  end

  ##
  # Internals
  def self.get(endpoint, data = nil)
    make_request(endpoint, data, :get)
  end

  def self.post(endpoint, data = nil)
    make_request(endpoint, data, :post)
  end

  def self.delete(endpoint, data = nil)
    make_request(endpoint, data, :delete)
  end

  def self.make_request(endpoint, data, method)
    uri = api_url(endpoint)
    request = case method
              when :get
                Net::HTTP::Get
              when :post
                Net::HTTP::Post
              when :delete
                Net::HTTP::Delete
              end.new(uri)
    request.set_form_data(data) if data
    set_headers(request)

    begin
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?) do |http|
        http.request(request)
      end
    rescue
      return '{ "errorCode": 500, "error": "Exception connecting to sheets server" }'
    end
    return "{ \"errorCode\": #{response.code}, \"error\": \"#{JSON.parse(response.body)['error']}\" }" unless response.is_a?(Net::HTTPSuccess)

    response.body
  end

  def self.api_url(endpoint)
    URI.join(ROOT_URL, endpoint)
  end

  def self.use_ssl?
    ROOT_URL =~ /\Ahttps:/
  end

  def self.set_headers(request)
    request['Authorization'] = API_TOKEN
  end

  class ApiException < StandardError
  end
end
