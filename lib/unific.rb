require 'singleton'

class Unific
  VERSION = '0.9.0'

  class Env
    @@trace = 0

    def initialize prev = {}
      @theta = prev.clone
    end

    def self.trace lvl
      if lvl
        @@trace = lvl
      else
        @@trace = @@trace + 1
      end
    end

    def self.untrace
      @@trace = 0
    end

    def fresh? x
      not @theta.has_key? x
    end

    def [] x
      @theta[x]
    end

    def extend mappings
      Env.new @theta.update mappings.reject {|k, v| k.kind_of? Wildcard or v.kind_of? Wildcard }
    end

    def to_s
      "{ " + @theta.map{|k, v| "#{k} => #{v}"}.join(", ") + "} "
    end

    # returns either `false' or the MGU of the two terms, which can be
    #    a.) vars
    #    b.) wildcards
    #    c.) any ruby Enumerable, in which case unification recurs on the members
    #    d.) any other ruby object (as a ground term)
    #
    # this is a functional interface -- a new env is returned with the MGU, as taken
    # against the bindings already in this env
    def unify a, b
      puts "unifying #{a.to_s} and #{b.to_s}" if @@trace > 0

      # if either is already bound, substitute up front
      a = instantiate a
      b = instantiate b

      # any remaining Var is fresh.
      if a.kind_of? Var and b.kind_of? Var
        extend a => b
      elsif a.kind_of? Var
        extend a => b
      elsif b.kind_of? Var
        extend b => a
      elsif a.kind_of? String and b.kind_of? String # strings should be treated as ground
        if a == b
          self
        else
          Unific::fail
        end
      elsif a.kind_of? Enumerable and b.kind_of? Enumerable
        return Unific::fail unless a.size == b.size
        a.zip(b).inject(self) do |e, pair|
          e.unify(pair[0], pair[1]) or return Unific::fail
        end
      else # both are ground terms
        if a == b
          self
        else
          Unific::fail
        end
      end
    end

    # substitute any bound variables in an arbitrary expression, using traversal rules of traverse
    def instantiate s
      _traverse s do |v|
        if fresh? v
          v
        else
          instantiate @theta[v]
        end
      end
    end

    # alpha-rename an expression (all variables get new variables of same name.  useful, e.g. to give
    # each Rule its own private copy of all of its variables.
    def rename s
      _traverse s do |v|
        if fresh? v
          n = Unific::Var.new(v.name)
          @theta[v] = n;
          n
        else
          instantiate @theta[v]
        end
      end
    end

    # helper for instantiate and rename
    # given an argument, if it is an:
    #   a.) var, replace it with the result of calling a block on it
    #   b.) enumerable, recur, instantiating it's members
    #   c.) any object, return it
    def _traverse s, &block
      case s
      when Unific::Wildcard
        s
      when Var
        block.call(s)
      # XXX XXX rulog had handling for Functor here, we may need to provide something similar?
      when String
        # in ruby 1.8, strings are enumerable, but we want them to be ground
        s
      when Enumerable
        s.map {|x| _traverse(x, &block)}
      else
        s
      end
    end
  end

  def self.unify a, b, env = Env.new
    env.unify a, b
  end

  class Var
    attr_accessor :name

    def initialize name = "new_var"
      @name = name
      self.freeze
    end
    
    def to_s
      "?#{@name}"
    end
  end

  class Wildcard < Var
    include Singleton

    def initialize
      super "_"
    end

    def to_s
      "_"
    end

    def == x
      true
    end
  end

  def self._
    Unific::Wildcard.instance
  end

  def self.fail
    false
  end

end
