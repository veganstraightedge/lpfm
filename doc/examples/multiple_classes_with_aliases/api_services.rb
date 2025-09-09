class UserAPI
  def find_by_id(id)
    get("/users/#{id}")
  end

  def create_record(data)
    post("/users", data)
  end

  def delete_record(id)
    delete("/users/#{id}")
  end

  def update(id, data)
    put("/users/#{id}", data)
  end

  private

  def get(path)
    http_client.get(path)
  end

  def post(path, data)
    http_client.post(path, data)
  end

  def put(path, data)
    http_client.put(path, data)
  end

  def delete(path)
    http_client.delete(path)
  end

  alias find find_by_id
  alias create create_record
  alias_method :destroy, :delete_record
end

class ProductAPI
  def find_by_id(id)
    get("/products/#{id}")
  end

  def create_record(data)
    post("/products", data)
  end

  def delete_record(id)
    delete("/products/#{id}")
  end

  def list_all
    get("/products")
  end

  private

  def get(path)
    http_client.get(path)
  end

  def post(path, data)
    http_client.post(path, data)
  end

  def put(path, data)
    http_client.put(path, data)
  end

  def delete(path)
    http_client.delete(path)
  end

  alias find find_by_id
  alias create create_record
  alias_method :destroy, :delete_record
end
