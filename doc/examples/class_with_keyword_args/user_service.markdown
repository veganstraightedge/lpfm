```ruby
class UserService
  def create_user(name:, email:, age: 25, active: true)
    User.new(name: name, email: email, age: age, active: active)
  end

  def update_user(id, name: nil, email: nil, age: nil)
    user = User.find(id)
    user.name = name if name
    user.email = email if email
    user.age = age if age
    user.save!
  end

  def find_users(limit: 10, offset: 0, active: true)
    User.where(active: active).limit(limit).offset(offset)
  end
end
```
