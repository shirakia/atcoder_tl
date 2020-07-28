module Util
  def download(url)
    sleep(1)

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    case response
    when Net::HTTPNotFound
      raise "HTTP not found"
    else
      response.body
    end
  end

  def set_logger(log_path)
    @logger = Logger.new(log_path)
  end

  def logger
    @logger
  end
end
