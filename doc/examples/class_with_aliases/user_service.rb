class UserService
  def initialize(database)
    @database = database
  end

  def find_user(id)
    @database.find(id)
  end

  def create_user(attributes)
    @database.create(attributes)
  end

  def update_user(id, attributes)
    @database.update(id, attributes)
  end

  def delete_user(id)
    @database.delete(id)
  end

  def get_all_users
    @database.all
  end

  private

  def validate_attributes(attributes)
    raise ArgumentError, "Invalid attributes" if attributes.empty?
  end

  alias find find_user
  alias create create_user
  alias update update_user
  alias_method :destroy, :delete_user
  alias_method :all, :get_all_users
end
