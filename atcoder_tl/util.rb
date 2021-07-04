module Util
  def download(url)
    sleep(0.2)

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPNotFound
      raise "HTTP not found"
    else
      response.body
    end
  end
end
