mdast = require 'mdast'
uuid = require 'uuid'
preprocess = require './preprocess'

ATTR_WHITELIST = ['href', 'src', 'target']

$ = React.createElement

toChildren = (node, defs, parentKey, tableAlign = []) ->
  return (for child, i in node.children
    compile(child, defs, parentKey+'_'+i, tableAlign))

isValidDocument = (doc) ->
  parsererrorNS = (new DOMParser()).parseFromString('INVALID', 'text/xml').getElementsByTagName("parsererror")[0].namespaceURI
  doc.getElementsByTagNameNS(parsererrorNS, 'parsererror').length == 0

getPropsFromHTMLNode = (node, attrWhitelist) ->
  string =
    if node.subtype is 'folded'
      node.startTag.value + node.endTag.value
    else if node.subtype is 'void'
      node.value
    else
      null
  if !string?
    return null

  parser = new DOMParser()
  doc = parser.parseFromString(string, 'text/html')
  if !isValidDocument(doc)
    return null

  attrs = doc.body.firstElementChild.attributes
  props = {}
  for i in [0...attrs.length]
    attr = attrs.item(i)
    if !attrWhitelist? or (attr.name in attrWhitelist)
      props[attr.name] = attr.value
  props

# Override by option
sanitize = null
highlight = null
compile = (node, defs, parentKey='_start', tableAlign = null) ->
  key = parentKey+'_'+node.type

  switch node.type
    # No child
    when 'text'           then rawValueWrapper node.value
    when 'escape'         then '\\'
    when 'break'          then $ 'br', {key}
    when 'horizontalRule' then $ 'hr', {key}
    when 'image'          then $ 'img', {key, src: node.src, title: node.title, alt: node.alt}
    when 'inlineCode'     then $ 'code', {key, className:'inlineCode'}, node.value
    when 'code'           then highlight node.value, node.lang, key

    # Has children
    when 'root'       then $ 'div', {key}, toChildren(node, defs, key)
    when 'strong'     then $ 'strong', {key}, toChildren(node, defs, key)
    when 'emphasis'   then $ 'em', {key}, toChildren(node, defs, key)
    when 'delete'     then $ 's', {key}, toChildren(node, defs, key)
    when 'paragraph'  then $ 'p', {key}, toChildren(node, defs, key)
    when 'link'       then $ 'a', {key, href: node.href, title: node.title}, toChildren(node, defs, key)
    when 'heading'    then $ ('h'+node.depth.toString()), {key}, toChildren(node, defs, key)
    when 'list'       then $ (if node.ordered then 'ol' else 'ul'), {key}, toChildren(node, defs, key)
    when 'listItem'
      className =
        if node.checked is true
          'checked'
        else if node.checked is false
          'unchecked'
        else
          ''
      $ 'li', {key, className}, toChildren(node, defs, key)
    when 'blockquote' then $ 'blockquote', {key}, toChildren(node, defs, key)

    when 'linkReference'
      for def in defs
        if def.type is 'definition' and def.identifier is node.identifier
          return $ 'a', {key, href: def.link, title: def.title}, toChildren(node, defs, key)
      # There's no corresponding definition; render reference as plain text.
      if node.referenceType is 'full'
        $ 'span', {key}, [
          '['
          toChildren(node, defs, key)
          ']'
          "[#{node.identifier}]"
        ]
      else # referenceType must be 'shortcut'
        $ 'span', {key}, [
          '['
          toChildren(node, defs, key)
          ']'
        ]

    # Footnote
    when 'footnoteReference'
      title = ''
      for def in defs
        if def.footnoteNumber is node.footnoteNumber
          title = def.link ? "..." # FIXME: use def.children (stringification needed)
          return $ 'sup', {key, id: "fnref#{node.footnoteNumber}"}, [
            $ 'a', {key: key+'-a', href: "#fn#{node.footnoteNumber}", title}, "#{node.footnoteNumber}"
          ]
      # There's no corresponding definition; render reference as plain text.
      $ 'span', {key}, "[^#{node.identifier}]"
    when 'footnoteDefinitionCollection'
      items = node.children.map (def, i) ->
        k = key+'-ol-li'+i
        # If `def` has children, we use them as `defBody`. And If `def` doesn't
        # have any, then it should have `link` text, so we use it.
        defBody = null
        if def.children?
          # If `def`s last child is a paragraph, append an anchor to `defBody`.
          # Otherwise we append nothing like Qiita does.
          # FIXME: We should not mutate a given AST.
          if (para = def.children[def.children.length - 1]).type is 'paragraph'
            para.children.push
              type: 'text'
              value: ' '
            para.children.push
              type: 'link'
              href: "#fnref#{def.footnoteNumber}"
              children: [{type: 'text', value: '↩'}]
          defBody = toChildren(def, defs, key)
        else
          defBody = $ 'p', {key: k+'-p'}, [
            def.link
            ' '
            $ 'a', {key: k+'-p-a', href: "#fnref#{def.footnoteNumber}"}, '↩'
          ]
        $ 'li', {key: k, id: "fn#{def.footnoteNumber}"}, defBody
      $ 'div', {key, className: 'footnotes'}, [
        $ 'hr', {key: key+'-hr'}
        $ 'ol', {key: key+'-ol'}, items
      ]

    # Table
    when 'table'       then $ 'table', {key}, toChildren(node, defs, key, node.align)
    when 'tableHeader'
      $ 'thead', {key}, [
        $ 'tr', {key: key+'-_inner-tr'}, node.children.map (cell, i) ->
          k = key+'-th'+i
          $ 'th', {key: k, style: {textAlign: tableAlign[i] ? 'left'}}, toChildren(cell, k)
      ]

    when 'tableRow'
      # $ 'tr', {key}  , [$ 'td', {key: key+'_inner-td'}, toChildren(node, defs, key)]
      $ 'tbody', {key}, [
        $ 'tr', {key: key+'-_inner-td'}, node.children.map (cell, i) ->
          k = key+'-td'+i
          $ 'td', {key: k, style: {textAlign: tableAlign[i] ? 'left'}}, toChildren(cell, k)
      ]
    when 'tableCell'   then $ 'span', {key}, toChildren(node, defs, key)

    # Raw html
    when 'html'
      if node.subtype is 'folded'
        k = key+'_'+node.tagName
        props = getPropsFromHTMLNode(node, ATTR_WHITELIST) ? {}
        props.key = k
        $ node.startTag.tagName, props, toChildren(node, defs, k)
      else if node.subtype is 'void'
        k = key+'_'+node.tagName
        props = getPropsFromHTMLNode(node, ATTR_WHITELIST) ? {}
        props.key = k
        $ node.tagName, props
      else if node.subtype is 'special'
        $ 'span', {
          key: key + ':special'
          style: {
            color: 'gray'
          }
        }, node.value
      else
        $ 'span', {
          key: key + ':parse-error'
          style: {
            backgroundColor: 'red'
            color: 'white'
          }
        }, node.value
    else
      throw node.type + ' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

htmlWrapperComponent = null
rawValueWrapper = null

module.exports = (raw, options = {}) ->
  sanitize = options.sanitize ? true
  rawValueWrapper = options.rawValueWrapper ? (text) -> text

  highlight = options.highlight ? (code, lang, key) ->
    $ 'pre', {key, className: 'code'}, [
      $ 'code', {key: key+'-_inner-code'}, code
    ]
  ast = mdast.parse raw, options
  [ast, defs] = preprocess(ast, options)
  ast = options.preprocessAST?(ast) ? ast
  compile(ast, defs)
