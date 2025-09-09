```ruby
class ConfigManager
  def initialize
    @settings = {}
    @cache = {}
  end

  def get_setting(key)
    @settings[key]
  end

  def set_setting(key, value)
    @settings[key] = value
    @cache.delete(key) if @cache.key?(key)
  end

  def admin.revoke_access(user_id)
    puts "Admin revoking access for user #{user_id}"
    audit_log("ACCESS_REVOKED", user_id: user_id)
  end

  def user.update_preferences(**preferences)
    user.preferences = user.preferences.merge(preferences)
    user.save!
  end

  class << self
    def configure(**options)
      @@global_config = options
      @@initialized = true
    end

    def reset_config
      @@global_config = {}
      @@initialized = false
    end

    def current_config
      @@global_config || {}
    end

    def bulk_import(*config_files, format: :json, **import_options)
      combined_config = {}

      config_files.each do |file|
        file_config = case format
        when :json
          JSON.parse(File.read(file))
        when :yaml
          YAML.load_file(file)
        else
          raise "Unsupported format: #{format}"
        end

        combined_config.merge!(file_config)
      end

      configure(**combined_config.merge(import_options))
    end
  end

  def clear_cache
    @cache.clear
    log_cache_cleared
  end

  private

  def audit_log(action, **metadata)
    timestamp = Time.now
    puts "[#{timestamp}] #{action}: #{metadata.inspect}"
  end

  def log_cache_cleared
    puts "Cache cleared at #{Time.now}"
  end
end
```
