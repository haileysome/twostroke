module Twostroke
  class ParseError < Error
  end
  
  class Parser
    attr_reader :statements
    
    def initialize(tokens)
      @i = -1
      @tokens = tokens
      @statements = []
    end
    
    def parse
      while @i + 1 < @tokens.length
        statements.push statement
      end
    end
  
  private
    def error!(msg)
      raise ParseError, "at line #{token.line}, col #{token.col}. #{msg}"
    end
    def assert_type(tok, *types)
      error! "Found #{tok.type}, expected #{types.join ", "}" unless types.include? tok.type
    end
    def stack
      @stack
    end
    def stack_top
      @stack.last
    end
    def token
      @tokens[@i] or raise ParseError, "unexpected end of input"
    end
    def next_token
      @i += 1
      token
    end
    def peek_token
      @tokens[@i + 1] or raise ParseError, "unexpected end of input"
    end
  
    ####################
    
    def statement
      st = case peek_token.type
      when :RETURN; send :return
      when :VAR; var
      else; expression
      end
      assert_type next_token, :SEMICOLON
      st
    end
    
    def expression
      expr = case peek_token.type
      when :FUNCTION; function
      when :STRING; string
      when :NUMBER; number
      when :BAREWORD; bareword
      else error! "Unexpected #{peek_token.type}"
      end
      if [:PLUS, :MINUS, :ASTERISK, :SLASH].include? peek_token.type
        op = next_token.type
        AST::UnsortedBinop.new left: expr, op: op, right: expression
      else
        expr
      end
    end
    
    def bareword
      assert_type next_token, :BAREWORD
      var = AST::Variable.new name: token.val
      if peek_token.type == :OPEN_PAREN
        c = call
        c.callee = var
        c
      else
        var
      end
    end
    
    def call
      assert_type next_token, :OPEN_PAREN
      c = AST::Call.new
      while peek_token.type != :CLOSE_PAREN
        c.arguments.push expression
        if peek_token.type == :COMMA
          next_token
          redo
        end
      end
      next_token
      c
    end
    
    def return
      assert_type next_token, :RETURN
      AST::Return.new expression: expression
    end
    
    def var
      assert_type next_token, :VAR
      assert_type next_token, :BAREWORD
      decl = AST::Declaration.new(name: token.val)
      return decl if peek_token.type == :SEMICOLON
      assert_type next_token, :EQUALS
      AST::Assignment.new left: decl, right: expression
    end
    
    def number
      assert_type next_token, :NUMBER
      AST::Number.new number: token.val
    end
    
    def string
      assert_type next_token, :STRING
      AST::String.new string: token.val
    end
    
    def function
      assert_type next_token, :FUNCTION
      fn = AST::Function.new arguments: [], statements: []
      error! unless [:BAREWORD, :OPEN_PAREN].include? next_token.type
      if token.type == :BAREWORD
        fn.name = token.val
        assert_type next_token, :OPEN_PAREN
      end
      while peek_token.type == :BAREWORD
        fn.arguments.push next_token.val
        next_token if peek_token.type == :COMMA
      end
      assert_type next_token, :CLOSE_PAREN
      assert_type next_token, :OPEN_BRACE
      while peek_token.type != :CLOSE_BRACE
        fn.statements.push statement
      end
      assert_type next_token, :CLOSE_BRACE
      fn
    end
  end
end