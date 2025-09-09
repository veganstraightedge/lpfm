class SortableItem
  include Comparable

  def compare_to(other)
    @priority <=> other.priority
  end
end
