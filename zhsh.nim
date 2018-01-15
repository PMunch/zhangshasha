import strutils

type
  Node = ref object
    label: string
    index: int
    children: seq[Node]
    leftmost: Node
  Tree = ref object
    root: Node
    l: seq[int]
    keyroots: seq[int]
    labels: seq[string]
  Tokenizer = object
    tokens: seq[tuple[token: string, isSep: bool]]
    token: int

proc `$`(node: Node): string =
  result = node.label
  if node.children.len != 0:
    result = result & "("
    for child in node.children:
      result = result & $child & " "
    result = result & ")"
var
  test = "f(a b(c))"
  tokenizer: Tokenizer
tokenizer.tokens = @[]
for word in test.tokenize({'(',')',' '}):
  echo word
  if word.isSep:
    if word.token.len > 1:
      for single in word.token:
        tokenizer.tokens.add((token: $single, isSep: true))
    else:
      tokenizer.tokens.add word
  else:
    tokenizer.tokens.add word

echo "-----"
for token in tokenizer.tokens:
  echo token

proc curToken(tokenizer: Tokenizer): tuple[token: string, isSep: bool] =
  tokenizer.tokens[tokenizer.token]

template doWhile(a: expr, b: stmt): stmt =
  while true:
    b
    if not a:
      break

proc parseString(node: var Node): Node =
  node.label = tokenizer.curToken.token
  tokenizer.token += 1
  if tokenizer.curToken.token == "(":
    tokenizer.token += 1
    doWhile tokenizer.curToken.token != ")":
      if tokenizer.curToken.token != " ":
        var newNode = new Node
        newNode.children = @[]
        node.children.add(parseString(newNode))
      else:
        tokenizer.token += 1
    tokenizer.token += 1
  return node

proc initTree(): Tree =
  result = Tree()
  result.root = new Node
  result.root.children = @[]
  result.root = parseString(result.root)
  if tokenizer.token != tokenizer.tokens.len:
    echo "Tokens not exhausted"
    quit 1

var t = initTree()
echo t.root
