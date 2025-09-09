class Config
  VERSION = "1.2.0"
  MAX_RETRIES = 3

  def get_version
    VERSION
  end

  def retry_limit
    MAX_RETRIES
  end
end
