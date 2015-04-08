# Returns true if the node is comment, CDATA, or any other non-ordinary tag.
isSpecialTag = (htmlNode) ->
  not /^<\/?[0-9a-z]/.test(htmlNode.value)

isStartTag = (htmlNode) ->
  # The value of an HTML node have one of the following forms:
  # '<foo ...>', '<foo .../>', '<foo ...>...</foo>', or '</foo>'.
  # Return true if it has one of the first two forms.
  not /\/[0-9a-z]+>$/i.test(htmlNode.value)

isEndTag = (htmlNode) ->
  /^(<\/[0-9a-z]+>)(\n\n<\/[0-9a-z]+>)*$/i.test(htmlNode.value)

isVoidElement = (elementName) ->
  voidElementNames = ['area', 'base', 'br', 'col', 'command', 'embed', 'hr', 'img', 'input', 'keygen', 'link', 'meta', 'param', 'source', 'track', 'wbr']
  voidElementNames.indexOf(elementName) != -1

isMergedNode = (node) ->
  pos = node.position
  pos.start.line is pos.end.line and /\n\n/.test(node.value)

getHTMLSubtype = (htmlNode) ->
  if isSpecialTag(htmlNode)
    'special'
  if isStartTag(htmlNode)
    if isVoidElement(getTagName(htmlNode))
      'startVoid'
    else
      'start'
  else if isEndTag(htmlNode)
    'end'
  else
    'startAndEnd'

# Returns tag name.
# If the node have merged start/end tags like "<b>\n\n<i>" or "</i>\n\n</b>",
# the name for both of them will be "b,i". Note that outer tag name comes first.
getTagName = (htmlNode) ->
  pattern = /<\/?([0-9a-z]+)/ig
  if htmlNode.subtype is 'startAndEnd'
    return pattern.exec(htmlNode.value)?[1]
  names = while (matches = pattern.exec(htmlNode.value))? then matches[1]
  if htmlNode.subtype is 'end'
    names = names.reverse()
  names.join(',')

# Adds the following properties to each HTML node in-place:
# { "subtype": ("start" | "end" | "startAndEnd" | "startVoid" | "special")
# , "tagName": tagName }
# Returns true if one or more nodes are annotated.
annotateHTMLNodes = (nodes) ->
  annotated = false
  for node in nodes
    if node.type is 'html'
      node.subtype = getHTMLSubtype(node)
      node.tagName = getTagName(node)
      annotated = true
    if node.children?
      annotated = annotateHTMLNodes(node.children) or annotated
  annotated

# Returns nodes by splitting start and end tags which are merged as
# "<b>\n\n<i>". As a side-effect, `position` of certain HTML nodes will be lost.
unmergeHTMLNodes = (nodes) ->
  processedNodes = []
  for node in nodes
    if node.type is 'html' and isMergedNode(node)
      for tag in node.value.split(/\n\n/)
        processedNodes.push
          type: 'html'
          subtype: getHTMLSubtype(value: tag)
          tagName: getTagName(value: tag)
          value: tag
    else
      if node.children?
        node.children = unmergeHTMLNodes(node.children)
      processedNodes.push(node)
  processedNodes

# Returns nodes by converting each occurrence of a series of nodes enclosed by
# a "start" and an "end" HTML node into one "folded" HTML node. A folded node
# has `folded` subtype and two additional properties, `startTag` and `endTag`.
# Its children is the enclosed nodes.
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

preprocess = (root) ->
  annotated = annotateHTMLNodes(root.children)
  if !annotated
    return # there are no HTML nodes to process
  root.children = unmergeHTMLNodes(root.children)
  root.children = foldHTMLNodes(root.children)

module.exports = preprocess
