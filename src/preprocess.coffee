preprocess = (root, sourceText, options) ->
  # Some yet-to-be-preprocessed HTML nodes are directly convertible to
  # "raw" HTML node - convert them.
  convertPreToRawHTML(root)

  # Literal `<pre>...</pre>` are often broken up into a series of HTML nodes.
  # Put them back together into a single "raw" HTML node.
  convertScatteredPreToRawHTML(root, sourceText)

  # Formalize HTML tags.
  root.children = decomposeHTMLNodes(root.children)
  root.children = foldHTMLNodes(root.children)

  # Process footnotes and and links.
  if options.footnotes
    mapping = defineFootnoteNumber(root).mapping
    applyFootnoteNumber(root, mapping)
  defs = removeDefinitions(root)
  if options.footnotes
    appendFootnoteDefinitionCollection(root, defs)

  # Sanitize HTML tags.
  root = wrapHTMLNodeInParagraph(root)
  root = sanitizeTag(root)

  [root, defs]

# Sets `footnoteNumber` property to every footnote reference node.
# Footnote number starts at 1 and is incremented whenever a new footnote
# identifier appears. Returns `{mapping, maxNumber}`
#
# Example (Markdown):
#
#     first footnote[^foo]            # footnoteNumber for [^foo] is 1
#     second footnote[^bar]           # footnoteNumber for [^bar] is 2
#     use first footnote again[^foo]  # footnoteNumber for [^foo] is 1
#     yet another footnote[^qux]      # footnoteNumber for [^qux] is 3
defineFootnoteNumber = (node, num = 1, mapping = {}) ->
  for child in node.children
    if child.type is 'footnoteReference'
      id = child.identifier
      unless mapping[id]?
        mapping[id] = num
        num += 1
      child.footnoteNumber = mapping[id]
    if child.children
      num = defineFootnoteNumber(child, num, mapping).maxNumber
  {mapping, maxNumber: num}

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

convertPreToRawHTML = (root) ->
  for node in root.children
    if node.type is 'html' and /^<pre[ >][^]*<\/pre>$/i.test(node.value)
      node.subtype = 'raw'

convertScatteredPreToRawHTML = (root, sourceText) ->
  preTexts = []
  startPreNode = null
  startParaIndex = null
  sourceLines = null

  for node, i in root.children
    isStart = (
      node.type is 'html' and
      /^<pre[ >]/i.test(node.value)
    )
    if isStart
      startPreNode = node
      startParaIndex = i

    paraLastNode = null
    isEnd = (
      startPreNode? and
      node.type is 'html' and
      /<\/pre>$/i.test(node.value)
    ) or (
      startPreNode? and
      node.type is 'paragraph' and
      (paraLastNode = node.children[node.children.length - 1]) and
      paraLastNode.type is 'html' and
      /<\/pre>$/i.test(paraLastNode.value)
    )
    if isEnd
      endPreNode = paraLastNode ? node
      sourceLines ?= sourceText.split(/^/m) # split lines _preserving newline character_
      sliceStart = startIndexFromPosition(startPreNode.position, sourceLines)
      sliceEnd = endIndexFromPosition(endPreNode.position, sourceLines)
      rawHTML = sourceText.slice(sliceStart, sliceEnd)
      preTexts.push
        startParaIndex: startParaIndex
        paraCount: i - startParaIndex + 1
        rawHTML: rawHTML
      startPreNode = null
      startParaIndex = null

  offset = 0
  for pre in preTexts
    rawHTMLNode = {type: 'html', subtype: 'raw', value: pre.rawHTML}
    start = pre.startParaIndex - offset
    root.children.splice(start, pre.paraCount, rawHTMLNode)
    offset = pre.paraCount - 1

startIndexFromPosition = (pos, lines) ->
  index = 0
  for i in [0...(pos.start.line - 1)]
    index += lines[i].length
  index += pos.start.column - 1
  index

endIndexFromPosition = (pos, lines) ->
  index = 0
  for i in [0...(pos.end.line - 1)]
    index += lines[i].length
  index += pos.end.column - 1
  index

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
    if node.type is 'html' and node.subtype is 'raw'
      processedNodes.push(node)
    else if node.type is 'html'
      fragmentNodes = decomposeHTMLNode(node)
      if fragmentNodes?
        processedNodes.push(fragmentNodes...)
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

# Wraps each top-level HTML node in a paragraph node.
#
# mdast wil put an HTML node directly in `root.children` without wrapping in a
# paragraph node if we write some block element in Markdown:
#
#     Markdown:
#         <div>foo
#
#         bar</div>
#
#     AST:
#         root.children = [ { type: "html", value: "<div>foo\nbar</div>" } ]
#
# However, we disallow writing block element tag in Markdown and convert such
# an HTML node into a series of text nodes by using `sanitizeTag()`.
# To form a paragraph node which have such text nodes as children, we wrap
# top-level HTML nodes in paragraph nodes before applying `sanitizeTag()`.
wrapHTMLNodeInParagraph = (root) ->
  children = []
  for child in root.children
    if child.type is 'html'
      children.push({type: 'paragraph', children: [child]})
    else
      children.push(child)
  root.children = children
  root

# A subset of [phrasing content] tags, plus RP and RT.
# We rejected some phrasing content tags from the set because it is able
# to write a semantically incorrect HTML with them, which leads to a crash of
# React.
#
# Rejected tags are kinds of:
#
#     - embedded contents like IFRAME, MATH, AUDIO, and VIDEO, except for IMG;
#     - interactive contents like BUTTON, KEYGEN, and PROGRESS;
#
# [phrasing content]: http://www.w3.org/TR/2011/WD-html5-20110525/content-models.html#phrasing-content-0
ALLOWED_TAG_NAMES = [
  'a', 'abbr', 'b', 'br', 'cite', 'code', 'del', 'dfn', 'em', 'i', 'img',
  'input', 'ins', 'kbd', 'mark', 'ruby', 'rp', 'rt', 'q', 's', 'samp', 'small',
  'span', 'strong', 'sub', 'sup', 'u', 'wbr',
]

# Flatten a disallowed kind of folded tag node into a series of nodes.
#
# Example:
#     node.children = [ { type: 'html, subtype: 'folded',
#                         startTag: startTag, endTag: endTag, children: [child1, child2] }, ... ]
#     # ^this is flattend into:
#     node.children = [ startTag, child1, child2, endTag, ... ]
#
# startTag and endTag are now freestanding, so they will be rendered as invalid HTML tags.
sanitizeTag = (node) ->
  return node unless node.children?
  children = []
  for child in node.children
    if child.subtype is 'folded' and child.tagName not in ALLOWED_TAG_NAMES
      children.push(child.startTag)
      Array::push.apply(children, sanitizeTag(child).children)
      children.push(child.endTag)
    else
      children.push(sanitizeTag(child))
  node.children = children
  node

module.exports = preprocess
