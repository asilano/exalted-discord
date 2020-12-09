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

  ##
  # Internals
  def self.get(endpoint)
    make_request(endpoint, nil, :get)
  end

  def self.post(endpoint, data)
    make_request(endpoint, data, :post)
  end

  def self.delete(endpoint, data)
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

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: use_ssl?) do |http|
      http.request(request)
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
