mdast = require 'mdast'
uuid = require 'uuid'
{DOMParser} = require 'xmldom'

$ = React.createElement
toChildren = (node, parentKey, tableAlign = []) ->
  return (for child, i in node.children
    align = tableAlign[i]
    compile(child, parentKey+'_'+i, align))

parser = new DOMParser()
isInvalidXML = (xmlString) ->
  parsererrorNS = parser.parseFromString('INVALID', 'text/xml').getElementsByTagName("parsererror")[0].namespaceURI
  dom = parser.parseFromString(xmlString, 'text/xml')

  if dom.getElementsByTagNameNS(parsererrorNS, 'parsererror').length > 0
    throw new Error('Error parsing XML')
  return dom;

sanitize = null
compile = (node, parentKey='_start', tableAlign = null) ->
  key = parentKey+'_'+node.type

  switch node.type
    # No child
    when 'text'           then node.value
    when 'escape'         then '\\'
    when 'inlineCode'     then $ 'code', {key, className:'inlineCode'}, node.value
    when 'code'           then $ 'code', {key, className:'code'}, node.value
    when 'break'          then $ 'br', {key}
    when 'horizontalRule' then $ 'hr', {key}
    when 'image'          then $ 'img', {key, src: node.src, title: node.title, alt: node.alt}

    # Has children
    when 'root'       then $ 'div', {key}, toChildren(node, key)
    when 'strong'     then $ 'strong', {key}, toChildren(node, key)
    when 'emphasis'   then $ 'em', {key}, toChildren(node, key)
    when 'delete'     then $ 's', {key}, toChildren(node, key)
    when 'paragraph'  then $ 'p', {key}, toChildren(node, key)
    when 'link'       then $ 'a', {key, href: node.href, title: node.title}, toChildren(node, key)
    when 'heading'    then $ ('h'+node.depth.toString()), {key}, toChildren(node, key)
    when 'list'       then $ (if node.ordered then 'ol' else 'ul'), {key}, toChildren(node, key)
    when 'listItem'
      className =
        if node.checked is true
          'checked'
        else if node.checked is false
          'unchecked'
        else
          ''
      $ 'li', {key, className}, toChildren(node, key)
    when 'blockquote' then $ 'blockquote', {key}, toChildren(node, key)

    # Table
    when 'table'       then $ 'table', {key}, toChildren(node, key, node.align)
    when 'tableHeader'
      $ 'thead', {key}, [
        $ 'tr', {key: key+'-_inner-tr'}, node.children.map (cell, i) ->
          k = key+'-th'+i
          $ 'th', {key: k, style: {textAlign: tableAlign ? 'left'}}, toChildren(cell, k)
      ]

    when 'tableRow'
      # $ 'tr', {key}  , [$ 'td', {key: key+'_inner-td'}, toChildren(node, key)]
      $ 'tbody', {key}, [
        $ 'tr', {key: key+'-_inner-td'}, node.children.map (cell, i) ->
          k = key+'-td'+i
          $ 'td', {key: k, style: {textAlign: tableAlign ? 'left'}}, toChildren(cell, k)
      ]
    when 'tableCell'   then $ 'span', {key}, toChildren(node, key)

    # Raw html
    when 'html'
      try
        isInvalidXML(node.value)
      catch e
        return $ 'span', {
          key: key + ':parse-error'
          style: {
            backgroundColor: 'red'
            color: 'white'
          }
        }, node.value

      value =
        if document? and sanitize
          dompurify = require 'dompurify' # it fire error in node on require
          dompurify.sanitize(node.value)
        else
          node.value
      $ 'div', {key}, [
        $ 'div', {key: key+'_raw', dangerouslySetInnerHTML:{__html: value}}
      ]
    else
      throw node.type + ' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

module.exports = (raw, options = {}) ->
  sanitize = options.sanitize ? true
  ast = mdast.parse raw, options
  compile(ast)
