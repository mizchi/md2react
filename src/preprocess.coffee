preprocess = (root, options) ->
  root.children = decomposeHTMLNodes(root.children)
  root.children = foldHTMLNodes(root.children)
  if options.footnotes
    mapping = defineFootnoteNumber(root)
    applyFootnoteNumber(root, mapping)
  defs = removeDefinitions(root)
  if options.footnotes
    appendFootnoteDefinitionCollection(root, defs)
  [root, defs]

# Sets `footnoteNumber` property to every footnote reference node.
# Footnote number starts at 1 and is incremented whenever a new footnote
# identifier appears.
#
# Example (Markdown):
#
#     first footnote[^foo]            # footnoteNumber for [^foo] is 1
#     second footnote[^bar]           # footnoteNumber for [^bar] is 2
#     use first footnote again[^foo]  # footnoteNumber for [^foo] is 1
#     yet another footnote[^qux]      # footnoteNumber for [^qux] is 3
defineFootnoteNumber = (node, num = 1, mapping = {}) ->
  return {} unless node.children?
  for child in node.children
    if child.type is 'footnoteReference'
      id = child.identifier
      unless mapping[id]?
        mapping[id] = num
        num += 1
      child.footnoteNumber = mapping[id]
    defineFootnoteNumber(child, num, mapping)
  mapping

# Sets `footnoteNumber` property to every footnote definition node using a
# given identifier-to-number mapping. `footnoteNumber` of a definition with
# undefined identifier will be 0.
#
# Example (Markdown):
#
#     Given mapping = `{"foo": 1, "bar": 2, "qux": 3}`,
#
#     [^bar]: this is bar    # footnoteNumber for this node is 2
#     [^foo]: this is foo    # footnoteNumber for this node is 1
#     [^qux]: this is qux    # footnoteNumber for this node is 3
#     [^xxx]: this is undef  # footnoteNumber for this node is 0
applyFootnoteNumber = (node, mapping) ->
  return unless node.children?
  for child in node.children
    # Workaround:
    # Footnote definition nodes are supposed to have `footnoteDefinition` type
    # but mdast v0.24.0 classifies them as `definition` type if their body
    # doesn't contain whitespace (e.g. `[^foo]: body_without_space`).
    isFootnoteDefLike = child.type is 'definition' and /^[^]/.test(child.identifier)
    if child.type is 'footnoteDefinition' or isFootnoteDefLike
      id = if isFootnoteDefLike then child.identifier.slice(1) else child.identifier
      child.footnoteNumber = mapping[id] || 0
    applyFootnoteNumber(child, mapping)

# Appends a `footnoteDefinitionCollection` node to `node.children` if `defs`
# contains one or more footnote definition nodes which `footnoteNumber` is > 0.
# Otherwise, do nothing.
# Elements of the collection are sorted by their `footnoteNumber` in ascending
# order.
appendFootnoteDefinitionCollection = (node, defs) ->
  footnoteDefs = (def for def in defs when def.footnoteNumber? and def.footnoteNumber > 0)
  footnoteDefs.sort (a, b) ->
    a.footnoteNumber - b.footnoteNumber
  if footnoteDefs.length > 0
    node.children.push({type: 'footnoteDefinitionCollection', children: footnoteDefs})

# Removes all footnote or link definition nodes from a given AST and returns
# removed nodes.
removeDefinitions = (node) ->
  return [] unless node.children?
  children = []
  defs = []
  for child in node.children
    if child.type in ['definition', 'footnoteDefinition']
      defs.push(child)
    else
      childDefs = removeDefinitions(child)
      Array::push.apply(defs, childDefs)
      children.push(child)
  node.children = children
  defs

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
