mdast = require 'mdast'

$ = React.createElement
toChildren = (node, parentKey) ->
  return (for child, i in node.children
    compile(child, parentKey+'_'+i))

compile = (node, parentKey='_start') ->
  key = parentKey+'_'+node.type
  switch node.type
    # No children nodes
    ## Has node.value
    when 'text'           then node.value
    when 'inlineCode'     then $ 'code', {key}, node.value
    when 'code'           then $ 'code', {key}, node.value
    when 'break'          then $ 'br', {key}
    when 'horizontalRule' then $ 'hr', {key}
    when 'image'          then $ 'img', {key, src: node.src, title: node.title, alt: node.alt}

    # Has children
    when 'root'       then $ 'div', {key}, toChildren(node, key)
    when 'strong'     then $ 'strong', {key}, toChildren(node, key)
    when 'emphasis'   then $ 'em', {key}, toChildren(node, key)
    when 'paragraph'  then $ 'p', {key}, toChildren(node, key)
    when 'link'       then $ 'a', {key, href: node.href, title: node.title}, toChildren(node, key)
    when 'heading'    then $ ('h'+node.depth.toString()), {key}, toChildren(node, key)
    when 'list'       then $ (if node.ordered then 'ol' else 'ul'), {key}, toChildren(node, key)
    when 'listItem'   then $ 'li', {key}, toChildren(node, key)
    when 'blockquote' then $ 'blockquote', {key}, toChildren(node, key)

    # Table
    # TODO: table may be bugged
    when 'table'       then $ 'table', {key}, toChildren(node, key)
    when 'tableHeader' then $ 'tr', {key}  , [$ 'th', {key: key+'_inner-th'}, toChildren(node, key)]
    when 'tableRow'    then $ 'tr', {key}  , [$ 'td', {key: key+'_inner-td'}, toChildren(node, key)]
    when 'tableCell'   then $ 'span', {key}, toChildren(node, key)

    # Raw html
    when 'html'
      if document? and sanitize
        dompurify = require 'dompurify' # it fire error in node on require
        $ 'div', {key, dangerouslySetInnerHTML:{__html: dompurify.sanitize(node.value)}}
      else
        $ 'div', {key, dangerouslySetInnerHTML:{__html: node.value}}
    else
      throw node.type + ' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

module.exports = (raw, options = {}) ->
  sanitize = options.sanitize ? true
  ast = mdast.parse raw, options
  compile(ast)
