# -*- encoding: utf-8 -*-

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
# _eval(one_plus_two) # => 3

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
# _eval(abs) # => 42
#
# abs = <<-EOS
# (App (Fun "abs" (App (Var "abs") (Int -42)))
#      (Fun ("x" (If (Var "x")
#                    (Int 0)
#                    (Sub (Int 0) (Var "x"))
#                    (Var "x")))))
# EOS
# _eval(abs) # => 42

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
# _eval(sum10000) # => 50005000


def main
  _eval(i) = i
end

case $PROGRAM_NAME
when __FILE__
  main
when /spec[^\/]*$/
  # {spec of the implementation}
end


