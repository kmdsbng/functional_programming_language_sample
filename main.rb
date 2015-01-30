# -*- encoding: utf-8 -*-
require 'active_support/all'

# http://qiita.com/esumii/items/0eeb30f35c2a9da4ab8a
# 
# E （式） ::= i                           （定数）
#   　　　  |  x                           （変数）
#  　　　   |  E1 - E2                     （引き算）
#   　　　  |  if E1 <= E2 then E3 else E4 （条件分岐）
#  　　　   |  function(x){E}              （引数xを受け取り、式Eの値を返す関数） 
#   　　　  |  E1(E2)                      （関数E1を引数E2に適用する）
# 
# * 式Eの構文は、以下の6種類のいずれかである
# * 定数の構文は、1つの整数iからなる（整数の定義はすでにあるものと仮定します）
# * 変数の構文は、1つの変数名xからなる（変数名は単なる文字列で表すことにします）
# * 引き算の構文は、2つの式E1とE2からなる
# * 条件分岐の構文は、4つの式E1, E2, E3, E4からなる
# * 関数の構文は、1つの変数名xと、1つの式Eからなる
# * 関数適用（関数呼び出し）の構文は、2つの式E1とE2からなる

# example 1
#
# let one_plus_two = Sub(Int 1, Sub(Int 0, Int 2)) (* 1 - (0 - 2) *)
#
# one_plus_two = <<-EOS
# (Sub (Int 1) (Sub (Int 0) (Int 2)))
# EOS
#
# _eval(one_plus_two) #=> 3

# example 2
# 
# let _Let(x, e1, e2) =
#   (* let x = e1 in e2 を (function(x){e2})(e1) と定義
#      （このように構文レベルの読み替えで実装された言語機能を
#      構文糖衣(syntax sugar)と言います） *)
#   App(Fun(x, e2), e1)
# 
# let abs =
#   (* let abs = function(x){if x<=0 then 0-x else x} in abs(-42) *)
#   _Let("abs",
#        Fun("x", If(Var "x", Int 0,
#                    Sub(Int 0, Var "x"),
#                    Var "x")),
#        App(Var "abs", Int(-42)))
#
# abs = <<-EOS
# ((let (_Let x e1 e2)
#        (App (Fun x e2) e1))
#    (_Let "abs"
#          (Fun ("x" (If (Var "x")
#                        (Int 0)
#                        (Sub (Int 0) (Var "x"))
#                        (Var "x"))))
#          (App (Var "abs") (Int -42)))
# EOS
# _eval(abs) #=> 42
#
# abs = <<-EOS
# (App (Fun "abs" (App (Var "abs") (Int -42)))
#      (Fun ("x" (If (Var "x")
#                    (Int 0)
#                    (Sub (Int 0) (Var "x"))
#                    (Var "x")))))
# EOS
# _eval(abs) #=> 42

# example 4
#
# let sum10000 =
#   (* let rec sum(n) = if n<=0 then 0 else sum(n-1)-(0-n) in sum(10000) *)
#   _Rec("sum", "n",
#        If(Var "n", Int 0, Int 0,
#           Sub(App(Var "sum", Sub(Var "n", Int 1)),
#               Sub(Int 0, Var "n"))),
#        Int 10000)
# # eval sum10000 ;;
# - : exp = Int 50005000
#
# sum10000 = <<-EOS
# (_Rec ("sum" "abs"
#       (If ((Var "n") (Int 0) (Int 0)
#            (Sub (App ((Var "sum") (Sub ((Var "n") (Int 1)))))
#                 (Sub ((Int 0) (Var "n"))))
#       (Int 10000)))))
# EOS
# _eval(sum10000) #=> 50005000

def main
  example1
end

def example1
  one_plus_two = <<-EOS
  (Sub (Int 1) (Sub (Int 0) (Int 2)))
  EOS

  puts "example 1"
  puts one_plus_two
  puts " => #{_eval(one_plus_two).inspect}"
  p build_ast(one_plus_two)
end

def _eval_inner(ast)
end


def _eval(source)
  ast = build_ast(source)
  _eval_inner(ast)
end

def build_ast(source)
  ast, _remain = build_ast_inner(source)
  ast
end

def build_ast_inner(source)
  remain = source
  ast = []
  until remain.blank?
    stripped = remain.strip
    if remain != stripped
      remain = stripped
      next
    end
    token, next_remain = fetch_token(remain)
    case token
    when '('
      child_ast, next_remain = build_ast_inner(next_remain)
      ast << child_ast
    when ')'
      return ast, next_remain
    else
      ast << token
    end
    remain = next_remain
  end

  [ast, remain]
end

# input : source_part
# retval : [token, remain]
def fetch_token(source_part)
  chars = source_part.split(//)
  if (['(', ')'].include?(chars[0]))
    [chars[0], chars[1..-1].join]
  elsif chars[0] == '"'
    end_quot_pos = chars[1..-1].index {|c| c == '"'}
    [chars[1..end_quot_pos].join, chars[end_quot_pos+2..-1].join]
  elsif chars[0] == '-'
    chars = chars[1..-1].join.strip.split(//)
    num_str = ""
    chars.each {|c|
      if (%w(0 1 2 3 4 5 6 7 8 9)).include?(c)
        num_str << c
      elsif ['(', ')', ' '].include?(c)
        break
      else
        raise "unexpected token '#{c}'"
      end
    }
    if num_str.blank?
      raise "invalid token : -"
    end

    [- num_str.to_i, chars[num_str.length..-1].join]
  elsif %w(0 1 2 3 4 5 6 7 8 9).include?(chars[0])
    num_str = ""
    chars.each {|c|
      if (%w(0 1 2 3 4 5 6 7 8 9)).include?(c)
        num_str << c
      elsif ['(', ')', ' '].include?(c)
        break
      else
        raise "unexpected token '#{c}'"
      end
    }

    [num_str.to_i, chars[num_str.length..-1].join]
  else

    token = ""
    chars.each {|c|
      if ['(', ')', ' '].include?(c)
        break
      else
        token << c
      end
    }

    [token.to_sym, chars[token.length..-1].join]
  end
end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  describe '#build_ast' do
    it 'build blank ast' do
      ast = build_ast('')
      expect(ast).to eq([])
    end

    it 'build one parenthes ast' do
      ast = build_ast('()')
      expect(ast).to eq([[]])
    end

    it 'build integer value' do
      ast = build_ast('(123)')
      expect(ast).to eq([[123]])
    end

    it 'build string value' do
      ast = build_ast('("hoge")')
      expect(ast).to eq([["hoge"]])
    end

    it 'build symbol token' do
      ast = build_ast('(Int 30)')
      expect(ast).to eq([[:Int, 30]])
    end
    it 'build tree ast' do
      ast = build_ast('(Sub (Int 30) (Var "x"))')
      expect(ast).to eq([[:Sub, [:Int, 30], [:Var, "x"]]])
    end
  end
end

