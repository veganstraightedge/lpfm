class EnumerableClass
  extend Enumerable

  def each
    yield 1
    yield 2
    yield 3
  end

  def length
    3
  end
end
