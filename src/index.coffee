mdast = require 'mdast'
$ = React.createElement
sanitize = null
compile = (node, key='') ->
  switch node.type
    when 'root'
      $ 'div', {key: key+'root'}, (compile(child, key+'root'+i) for child, i in node.children)
    when 'text'
      node.value
    when 'strong'
      $ 'strong', {key: key+'strong'}, (compile(child, key+'strong'+i) for child, i in node.children)
    when 'emphasis'
      $ 'em', {key: key+'emphasis'}, (compile(child, key+'emphasis'+i) for child, i in node.children)
    when 'horizontalRule'
      $ 'hr', key: key+'hr'
    when 'inlineCode'
      # TODO: code is valide?
      $ 'code', {key: key+'inlineCode'}, node.value
    when 'code'
      # TODO: code is valide?
      $ 'code', {key: key+'code'}, node.value
    when 'heading'
      tag = 'h'+node.depth.toString()
      $ tag, {key: key+tag}, (compile(child, key+tag+i) for child, i in node.children)
    when 'paragraph'
      $ 'p', {key: key+'paragraph'}, (compile(child, key+'paragraph'+i) for child, i in node.children)
    when 'list'
      tag = if node.ordered then 'ol' else 'ul'
      $ tag, {key: key+'list'}, (compile(child, key+tag+i) for child, i in node.children)
    when 'link'
      $ 'a', {key: key+'link', href: node.href, title: node.title}, (compile(child, key+'link'+i) for child, i in node.children)
    when 'image'
      $ 'img', {key: key+'image', src: node.src, title: node.title, alt: node.alt}
    when 'blockquote'
      $ 'blockquote', {key: key+'bq'}, (compile(child, key+'bq'+i) for child, i in node.children)
    when 'table'
      # TODO: fixme
      $ 'table', {key: key+'table'}, (compile(child, key+'table'+i) for child, i in node.children)
    when 'tableHeader'
      $ 'tr', {key: key+'tableHeader'}, (($ 'th', {key: key+'tr-th'}, compile(child, key+'tableHeader'+i)) for child, i in node.children)
    when 'tableRow'
      $ 'tr', {key: key+'tableRow'}, (($ 'td', {key: key+'td-th'}, compile(child, key+'tableRow'+i)) for child, i in node.children)
    when 'tableCell'
      $ 'span', {key: key+'tableCell'}, (compile(child, key+'tableCell'+i) for child, i in node.children)
    when 'listItem'
      # TODO: what is loose property?
      $ 'li', {key: key+'li'}, (compile(child, key+'li'+i) for child, i in node.children)
    when 'html'
      if window? and sanitize
        dompurify = require 'dompurify'
        $ 'div', key: key+'html', dangerouslySetInnerHTML:{__html: dompurify.sanitize(node.value)}
      else
        $ 'div', key: key+'html', dangerouslySetInnerHTML:{__html: node.value}
    else
      # console.log node
      throw node.type +' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

module.exports = (raw, _sanitize = true) ->
  sanitize = _sanitize
  ast = mdast.parse raw
  compile(ast, '__entry')
