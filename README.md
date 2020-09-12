# lambda
create simple language (and processor)!!

cf.
- https://github.com/sdiehl/write-you-a-haskell
- [katatoshi/tapl](https://github.com/katatoshi/tapl)
- [つくってあそぼ ラムダ計算インタプリタ](https://speakerdeck.com/kmc_jp/implement-an-interpreter-of-lambda-calculus?slide=17)
- TaPL

create an AST interpreter like the one below
```
ソースコード -字句解析-> トークン -構文解析-> AST -解釈実行-> 結果
```

## 環境構築
for mac: asdf で入れた stack はうまく動かないので注意。 homebrew で stack を入れるのが楽

``` shell
# stack の設定
$ brew install stack
$ emacs .zshenv
if whence stack > /dev/null; then
  export PATH="$(stack path --local-bin):$PATH"
fi

if whence stack > /dev/null; then
  export PATH="$(stack path --compiler-bin):$PATH"
fi

# repository download
$ git clone https://github.com/yorisilo/lambda
$ cd lambda

# build できるか確認
$ stack build

# ghc の repl 起動
# これを多用して色々コードを実行させていく
# stack ghci
```

## 青写真
型なしラムダ計算ってこんなやつ。

- `(λx.x) y`
- `(λx.x) (λx.x)`
- `(λx.λy.λz.xy(xz))`

特徴
- チューリング完全なので、こいつだけで色々書ける。
- データはエンコーディングして使う。 cf. チャーチ数等
  - TODO: エンコーディングの具体例など追記する

# untyped lambda calculus
## syntax

```
e ::=       (term)
    | x     (variable)
    | λx.e  (lambda abstraction)
    | e e   (function application)

v ::=       (value)
    | λx.e  (lambda abstraction)
```

## inference(reduction, evaluation) rules
small step の 操作的意味論で定義された call-by-value の評価規則

- call-by-value: まず外側の redex を簡約の候補にする。 そして、e2 が値に簡約されていれば、その redex を簡約する。
  e2 が値じゃない場合、先にそちらの簡約を行う。
  つまり、関数の引数から先に簡約するような評価規則。
  - redex: (λx.e1) e2 の形の項 = v e みたいな形の項のこと


```
------------------ (beta)
λx.e v -> e[x<-v]

   e1 -> e1'
------------------ (app1)
e1 e2 -> e1' e2

   e2 -> e2'
------------------ (app2)
v1 e2 -> v1 e2'
```

ex.

```
id ::= λx.x
id (id (λz.id z)) -> id (λz.id z) -> λz.id z
```


exercice.

```
(λy.z) (λy.z) -> ???
```

<details>

```
(λy.z) (λy.z) -> z
```

</details>


```
(λz.(λy.z)) (λy.z) -> ???
```

<details>

```
(λz.(λy.z)) (λy.z) -> λz.λz.λz.λz...
```

</details>

```
(λx.x x) ((λy.y) z) -> ???
```

<details>

```
(λx.x x) ((λy.y) z) -> stack
```

</details>

### α 変換
`λx.x` と `λy.y` は同じってことを表している規則

```
------------------
λx.e -> λy.e[x<-y]
```

### FV: 自由変数の集合

```
FV(x)      = {x}
FV (λx.e)  = FV (e) \ {x}
FV (e1 e2) = FV (e1) ∪ FV (e2)
```

### substition
`e[x<-s]`: `e` に含まれる自由変数 `x` を `s` に置換する

`s` は閉じた項 (自由変数の無い項) とする

substition の定義

```
y[x<-s]      = if x == y then s else y
(λy.e)[x<-s] = if x == y && y ∉ FV(s) then λy.e else (λy.e[x<-s])
(t u)[x<-s]  = (t[x<-s]) (u[x<-s])
```

#### 束縛変数と自由変数
- 束縛変数: lambda abstraction によって束縛されている変数
- 自由変数: 束縛変数ではない変数
以下の項における `x`, `y` が束縛変数、 `z` が自由変数である。

```
λx.λy.xyz
```
