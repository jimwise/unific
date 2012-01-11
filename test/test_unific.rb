require "test/unit"
require "unific"

class TestUnific < Test::Unit::TestCase

  def test_unify_simple
    assert Unific::unify(42, 42)
    assert Unific::unify("abc", "abc")
    assert Unific::unify(42, Unific::Var.new)
    assert Unific::unify(Unific::Var.new, 42)
    assert Unific::unify(Unific::Var.new, Unific::Var.new)
    v1 = Unific::Var.new("v1")
    assert Unific::unify(v1, v1)
    assert Unific::unify(v1, 42).unify(v1, 42)
    assert !Unific::unify(v1, 42).unify(v1, 35)
  end

  def test_unify_enum
    assert Unific::unify([1, 2, 3], [1, 2, 3])
    assert !Unific::unify([1, 2, 3], [1, 2, 3, 4])
    assert Unific::unify([1, 2, 3], [1, Unific::Var.new, 3])
    assert Unific::unify({"a" => 1}, {"a" => 1})
    assert !Unific::unify({"a" => 2}, {"a" => 3})
  end

  def test_unify_recursive_enum
    assert Unific::unify([["a", 1], ["b", 2]], [["a", 1], ["b", 2]])
    assert !Unific::unify([["a", 1], ["b", 2]], [["x", 3], ["y", 4]])
    assert Unific::unify([[1,2], [3,4], [5,6]], [[1,2], Unific::Var.new, [5,6]])
  end

  def test_wildcard
    assert Unific::unify(Unific::_, 42);
    assert Unific::unify(Unific::_, Unific::Var.new);
    v1 = Unific::Var.new("v1")
    e1 = Unific::Env.new
    e2 = Unific::unify(v1, 42);
    assert Unific::unify(v1, Unific::_, e2);
    assert Unific::unify([1, 2, 3], Unific::_)
    assert Unific::unify([1, Unific::_, 3], [1, 2, 3])
  end

  def test_vars
    v1 = Unific::Var.new("v1")
    v2 = Unific::Var.new("v2")
    assert Unific::unify(v1, v2).unify(v1, 42).unify(v2, 42)
    assert !Unific::unify(v1, v2).unify(v1, 42).unify(v2, 35)
    assert Unific::unify(v1, 42).unify(v1, v2).unify(v2, 42)
    assert !Unific::unify(v1, 42).unify(v1, v2).unify(v2, 35)
  end

end
