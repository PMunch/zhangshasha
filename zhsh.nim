import strutils
import sequtils
import math

type
  Node* = ref object
    label*: string
    index: int
    children*: seq[Node]
    leftmost: Node
  Tree* = ref object
    root*: Node
    l: seq[int]
    keyroots: seq[int]
    labels: seq[string]
  Tokenizer = object
    tokens: seq[tuple[token: string, isSep: bool]]
    token: int

proc `$`*(node: Node): string =
  result = node.label
  if node.children.len != 0:
    result = result & "("
    for child in node.children:
      result = result & $child & " "
    result = result & ")"

proc tokenize*(str: string): Tokenizer =
  result.tokens = @[]
  for word in str.tokenize({'(',')',' '}):
    if word.isSep:
      if word.token.len > 1:
        for single in word.token:
          result.tokens.add((token: $single, isSep: true))
      else:
        result.tokens.add word
    else:
      result.tokens.add word

proc curToken(tokenizer: Tokenizer): tuple[token: string, isSep: bool] =
  tokenizer.tokens[tokenizer.token]

template doWhile(a: expr, b: stmt): stmt =
  while true:
    b
    if not a:
      break

proc parseString(node: var Node, tokenizer: var Tokenizer): Node =
  node.label = tokenizer.curToken.token
  tokenizer.token += 1
  if tokenizer.token >= tokenizer.tokens.len:
    return node
  if tokenizer.curToken.token == "(":
    tokenizer.token += 1
    doWhile tokenizer.curToken.token != ")":
      if tokenizer.curToken.token != " ":
        var newNode = new Node
        newNode.children = @[]
        node.children.add(parseString(newNode, tokenizer))
      else:
        tokenizer.token += 1
    tokenizer.token += 1
  return node

proc initTree*(tokenizer: var Tokenizer): Tree =
  result = Tree()
  result.root = new Node
  result.root.children = @[]
  result.root = parseString(result.root, tokenizer)
  if tokenizer.token != tokenizer.tokens.len:
    echo "Tokens not exhausted"
    quit 1

proc traverse(node: Node, labels: var seq[string]): seq[string] =
  for i in node.children:
    labels = traverse(i, labels)
  labels.add(node.label)
  return labels

proc traverse(tree: Tree) =
  discard traverse(tree.root, tree.labels)

proc index(node: Node, index: var int): int =
  for i in node.children:
    index = index(i, index)
  index += 1
  node.index = index
  return index

proc index(tree: Tree) =
  var i = 0
  discard index(tree.root, i)

proc leftmost(node: Node) =
  if node == nil:
    return
  for i in node.children:
    leftmost(i)
  if node.children.len == 0:
    node.leftmost = node
  else:
    node.leftmost = node.children[0].leftmost

proc leftmost(tree: Tree) =
  leftmost(tree.root)

proc getl(node: Node, l: var seq[int]): seq[int] =
  for i in node.children:
    l = getl(i, l)
  l.add(node.leftmost.index)
  return l

proc getl(tree: Tree) =
  leftmost(tree)
  var tmpSeq = newSeq[int]()
  tree.l = getl(tree.root, tmpSeq)

proc getkeyroots(tree: Tree) =
  for i in 0..<tree.l.len:
    var flag = 0
    for j in (i+1)..<tree.l.len:
      if tree.l[j] == tree.l[i]:
        flag = 1
    if flag == 0:
      tree.keyroots.add(i + 1)

proc zhangShasha*(tree1: Tree, tree2: Tree): int =
  tree1.l = @[]
  tree1.keyroots = @[]
  tree1.labels = @[]
  tree2.l = @[]
  tree2.keyroots = @[]
  tree2.labels = @[]

  tree1.index()
  tree1.getl()
  tree1.getkeyroots()
  tree1.traverse()
  tree2.index()
  tree2.getl()
  tree2.getkeyroots()
  tree2.traverse()

  var td = newSeqWith(tree1.l.len + 1, newSeq[int](tree2.l.len + 1))

  proc treedist(l1, l2: seq[int], i, j: int, tree1, tree2: Tree): int =
    var
      forestdist = newSeqWith(l1.len + 1, newSeq[int](l2.len + 1))
    const
      delete = 1
      insert = 1
      relabel = 1

    forestdist[0][0] = 0
    for i1 in l1[i - 1]..i:
      forestdist[i1][0] = forestdist[i1 - 1][0] + delete
    for j1 in l2[j - 1]..j:
      forestdist[0][j1] = forestdist[0][j1 - 1] + insert
    for i1 in l1[i - 1]..i:
      for j1 in l2[j - 1]..j:
        let
          i_temp = if l1[i - 1] > i1 - 1: 0 else: i1 - 1
          j_temp = if l2[j - 1] > j1 - 1: 0 else: j1 - 1
        if l1[i1 - 1] == l1[i - 1] and l2[j1 - 1] == l2[j - 1]:
          let cost = if tree1.labels[i1 - 1] == tree2.labels[j1 - 1]: 0 else: relabel
          forestdist[i1][j1] = min(
            min(forestdist[i_temp][j1] + delete, forestdist[i1][j_temp] + insert),
            forestdist[i_temp][j_temp] + cost)
          td[i1][j1] = forestdist[i1][j1]
        else:
          let
            i1_temp = l1[i1 - 1] - 1
            j1_temp = l2[j1 - 1] - 1
            i_temp2 = if l1[i - 1] > i1_temp: 0 else: i1_temp
            j_temp2 = if l2[j - 1] > j1_temp: 0 else: j1_temp
          forestdist[i1][j1] = min(
            min(forestdist[i_temp][j1] + delete, forestdist[i1][j_temp] + insert),
            forestdist[i_temp2][j_temp2] + td[i1][j1])
    return forestdist[i][j]

  for i in 1..tree1.keyroots.len:
    for j in 1..tree2.keyroots.len:
      var
        r1 = tree1.keyroots[i-1]
        r2 = tree2.keyroots[j-1]
      td[r1][r2] = treedist(tree1.l, tree2.l, r1, r2, tree1, tree2)

  return td[tree1.l.len][tree2.l.len]
