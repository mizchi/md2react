preprocess = (root) ->
  root.children = decomposeHTMLNodes(root.children)
  root.children = foldHTMLNodes(root.children)
  root

# Returns nodes by converting each occurrence of a series of nodes enclosed by
# a "start" and an "end" HTML node into one "folded" HTML node. A folded node
# has `folded` subtype and two additional properties, `startTag` and `endTag`.
# Its children are the enclosed nodes.
foldHTMLNodes = (nodes) ->
  processedNodes = []
  for node in nodes
    if node.subtype is 'end'
      startTagIndex = null
      for pNode, index in processedNodes
        if pNode.subtype is 'start' and pNode.tagName is node.tagName
          startTagIndex = index
      if !startTagIndex?
        processedNodes.push(node)
        continue
      startTag = processedNodes[startTagIndex]
      children = processedNodes.splice(startTagIndex).slice(1)
      folded =
        type: 'html'
        subtype: 'folded'
        tagName: startTag.tagName
        startTag: startTag
        endTag: node
        children: children
      processedNodes.push(folded)
    else
      if node.children?
        node.children = foldHTMLNodes(node.children)
      processedNodes.push(node)
  processedNodes

# Decomposes HTML nodes in a given array of nodes and their children. Sets
# `subtype` of an HTML node to `malformed` if the node could not be decomposed.
decomposeHTMLNodes = (nodes) ->
  processedNodes = []
  for node in nodes
    if node.type is 'html'
      fragmentNodes = decomposeHTMLNode(node)
      if fragmentNodes?
        Array.prototype.push.apply(processedNodes, fragmentNodes)
      else
        node.subtype = 'malformed'
        processedNodes.push(node)
    else
      if node.children?
        node.children = decomposeHTMLNodes(node.children)
      processedNodes.push(node)
  processedNodes

# Decomposes a given HTML node into text nodes and "simple" HTML nodes.
# If decomposition failed, returns null.
#
# mdast can emit "complex" HTML node whose value is like "<b>text</b>".
# Take this value as an example, this method breaks it down to three nodes:
# HTML start tag node "<b>"; text node "text"; and HTML end tag node "</b>".
#
# Each decomposed HTML node has the `subtype` property.
# See `createNodeFromHTMLFragment()` for the possible values.
decomposeHTMLNode = (node) ->
  value = node.value
  # mdast may insert "\n\n" between adjacent HTML tags.
  if node.position.start.line is node.position.end.line
    value = value.replace(/\n\n/, '')
  fragments = decomposeHTMLString(value)
  fragments?.map(createNodeFromHTMLFragment)

# Splits a given string into an array where each element is ether an HTML tag
# or a string which doesn't contain angle brackets, then returns the array.
# If a given string contains lone angle brackets, returns null.
#
# Example:
#     Given   "foo<b>bar<br></b>baz"
#     Returns ["foo", "<b>", "bar", "<br>", "</b>", "baz"]
#     Given   "<b> oops >_< </b>"
#     Returns null
decomposeHTMLString = (str) ->
  if str is ''
    return null
  matches = str.match(/<[^>]*>|[^<>]+/g)
  sumLength = matches.reduce(((len, s) -> len+s.length), 0)
  if sumLength isnt str.length
    null
  else
    matches

createNodeFromHTMLFragment = (str) ->
  if /^[^<]/.test(str)
    return {
      type: 'text'
      value: str
    }
  [..., slash, name] = /^<(\/?)([0-9A-Z]+)/i.exec(str) ? []
  subtype =
    if !name?
      'special'
    else if slash is '/'
      'end'
    else if isVoidElement(name)
      'void'
    else
      'start'
  type: 'html'
  subtype: subtype
  tagName: name
  value: str

isVoidElement = (elementName) ->
  voidElementNames = ['area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr']
  voidElementNames.indexOf(elementName) != -1

module.exports = preprocess
