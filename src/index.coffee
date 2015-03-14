mdast = require 'mdast'

$ = React.createElement
toChildren = (node, parentKey) ->
  return (for child, i in node.children
    compile(child, parentKey+'_'+i))

sanitize = null
compile = (node, parentKey='_start') ->
  key = parentKey+'_'+node.type

  switch node.type
    # No child
    when 'text'           then node.value
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
    when 'table'       then $ 'table', {key}, toChildren(node, key)
    when 'tableHeader' then $ 'tr', {key}  , [$ 'th', {key: key+'_inner-th'}, toChildren(node, key)]
    when 'tableRow'    then $ 'tr', {key}  , [$ 'td', {key: key+'_inner-td'}, toChildren(node, key)]
    when 'tableCell'   then $ 'span', {key}, toChildren(node, key)

    # Raw html
    when 'html'
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
