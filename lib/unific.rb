require 'singleton'
require 'set'

module Unific

  VERSION = '0.12'

  # An environment (set of variable bindings) resulting from unification
  class Env
    @@trace = 0

    # Allocate a new environment.  Usually not needed -- use Unific::unify, instead.
    #
    # The new environment will be empty unless a hash of variable bindings
    # is included.  Use this with care.
    def initialize prev = {}
      @theta = prev.clone
    end

    # Turn on tracing (to STDERR) of Unific operations
    #
    # intended for use by Unific::trace
    #
    # The optional level argument sets the verbosity -- if not passed, each
    # call to this method increases verbosity
    def self.trace lvl #:nodoc:
      if lvl
        @@trace = lvl
      else
        @@trace = @@trace + 1
      end
    end

    # Turn off tracing (to STDERR) of Unific operations
    #
    # intended for use by Unific::trace
    def self.untrace #:nodoc:
      @@trace = 0
    end

    # Return whether a given variable is fresh (not bound) in this environment
    def fresh? x
      not @theta.has_key? x
    end

    # Return the binding of a variable in this environment, or +nil+ if it is unbound
    def [] x
      @theta[x]
    end

    # private helper to extend this environment with one or more new mappings
    def _extend mappings
      Env.new @theta.update mappings.reject {|k, v| k.kind_of? Wildcard or v.kind_of? Wildcard }
    end

    def to_s
      "{ " + @theta.map{|k, v| "#{k} => #{v}"}.join(", ") + "} "
    end

    # Unify two values against this environment, returning a new environment
    #
    # If the two values cannot be unified, `false' is returned.  If they can, a _new_
    # environment is returned which is this environment extended with any new bindings
    # created by unification.
    # 
    # Each value to unify can be
    #
    # a. a Unific::Var variable
    # b. the wildcard variable, Unific::_
    # c. any ruby Enumerable except a String, in which case unification recurs on the members
    # e. a String or any other ruby object (as a ground term -- unification succeeds
    # if the two are equal (with '=='))
    #
    # In logic programming terms, the returned env is the Most General Unifier (MGU) of the two
    # terms
    def unify a, b
      puts "unifying #{a.to_s} and #{b.to_s}" if @@trace > 0

      # if either is already bound, substitute up front
      a = instantiate a
      b = instantiate b

      # any remaining Var is fresh.
      if a.kind_of? Var and b.kind_of? Var
        _extend a => b
      elsif a.kind_of? Var
        _extend a => b
      elsif b.kind_of? Var
        _extend b => a
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

    # Given a value, substitute any variables present in the term.
    #
    # If the passed value is a Ruby Enumerable other than a String, recurs on the members of
    # the Enumerable.  Unlike #[], also repeatedly substitutes each variable until it gets a
    # ground (non-variable) term or a free variable
    def instantiate s
      _traverse s do |v|
        if fresh? v
          v
        else
          instantiate @theta[v]
        end
      end
    end

    # Perform alpha renaming on an expression
    #
    # Alpha-renaming an expression replaces all fresh variables in the
    # expression with new variables of the same name.  This is used by rulog
    # to to give each Rule its own private copy of all of its variables.
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

    # Return just the variables from an expression, as a flat array
    def variables s
      res = []
      _traverse s do |v|
        res << v
      end
      res.uniq
    end

    def bindings
      @theta.keys
    end

    # forward definition, see comment below
    module ::Rulog #:nodoc:
    end
    class ::Rulog::Functor #:nodoc:
    end

    # private helper for instantiate and rename
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
      when Rulog::Functor # XXX XXX messy -- this is the only place Unific knows about the rest of Rulog
        Rulog::Functor.new _traverse(s.f, &block), *_traverse(s.args, &block)
      when String
        # in ruby 1.8, strings are enumerable, but we want them to be ground
        s
      when Enumerable
        s.map {|x| _traverse(x, &block)}
      else
        s
      end
    end

    private :_extend, :_traverse
  end

  # Unify two terms against an empty environment
  # 
  # See README.rdoc or Env#unify for details
  #
  # If the two values cannot be unified, `false' is returned.  If they can, a _new_
  # environment is returned which is this environment extended with any new bindings
  # created by unification.
  #--
  # XXX This documentation must be kept in sync with that for Env#unify
  #++
  def self.unify a, b, env = Env.new
    env.unify a, b
  end

  # A unification variable
  class Var
    attr_accessor :name

    # Create a new variable
    #
    # The optional argument provides a name for use in printing the variable
    def initialize name = "new_var"
      @name = name
      self.freeze
    end
    
    # Return a string representing a variable
    #
    # A variable named"foo" is presented as as "?foo"
    def to_s
      "?#{@name}"
    end
  end

  # The unique Unific wildcard variable
  class Wildcard < Var
    include Singleton

    # The wildcard variable is named "_"
    def initialize #:nodoc:
      super "_"
    end

    # The wildcard variable is presented as "_"
    def to_s
      "_"
    end

    # The wildcard variable matches any value
    def == x
      true
    end
  end

  # Return the Unific wildcard variable
  def self._
    Unific::Wildcard.instance
  end

  # Turn on tracing (to STDERR) of Unific operations
  #
  # The optional level argument sets the verbosity -- if not passed, each
  # call to this method increases verbosity
  def self.trace lvl = false
    Unific::Env::trace lvl
  end

  # Turn off tracing (to STDERR) of Unific operations
  def self.untrace
    Unific::Env::untrace untrace
  end

  # Return false
  #
  # Placeholder for possible future expansion of failed unification behavior
  def self.fail
    false
  end

end
