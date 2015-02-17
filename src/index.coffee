mdast = require 'mdast'
$ = React.createElement
sanitize = null
compile = (node, key='') ->
  switch node.type
    when 'root'
      $ 'div', {key: key}, (compile(child, 'root'+i) for child, i in node.children)
    when 'text'
      node.value
    when 'strong'
      $ 'strong', {key: key}, (compile(child, 'strong'+i) for child, i in node.children)
    when 'emphasis'
      $ 'em', {key: key}, (compile(child, 'emphasis'+i) for child, i in node.children)
    when 'horizontalRule'
      $ 'hr'
    when 'inlineCode'
      # TODO: code is valide?
      $ 'code', {key: key}, [node.value]
    when 'code'
      # TODO: code is valide?
      $ 'code', {key: key}, [node.value]
    when 'heading'
      tag = 'h'+node.depth.toString()
      $ tag, {key: key}, (compile(child, tag+i) for child, i in node.children)
    when 'paragraph'
      $ 'p', {key: key}, (compile(child, 'paragraph'+i) for child, i in node.children)
    when 'list'
      tag = if node.ordered then 'ol' else 'ul'
      $ tag, {key: key}, (compile(child, tag+i) for child, i in node.children)
    when 'link'
      $ 'a', {key: key, href: node.href, title: node.title}, (compile(child, 'link'+i) for child, i in node.children)
    when 'image'
      $ 'img', {key: key, src: node.src, title: node.title, alt: node.alt}
    when 'blockquote'
      $ 'blockquote', {key: key}, (compile(child, 'bq'+i) for child, i in node.children)
    when 'table'
      # TODO: fixme
      $ 'table', {key: key}, (compile(child, i) for child, i in node.children)
    when 'tableHeader'
      $ 'tr', {key: key}, (($ 'th', {key: 'tr-th'}, compile(child, i)) for child, i in node.children)
    when 'tableRow'
      $ 'tr', {key: key}, (($ 'td', {key: 'td-th'}, compile(child, i)) for child, i in node.children)
    when 'tableCell'
      $ 'span', {key: key}, (compile(child, i) for child, i in node.children)
    when 'listItem'
      # TODO: what is loose property?
      $ 'li', {}, (compile(child, 'li'+i) for child, i in node.children)
    when 'html'
      if window? and sanitize
        dompurify = require 'dompurify'
        $ 'div', key: key, dangerouslySetInnerHTML:{__html: dompurify.sanitize(node.value)}
      else
        $ 'div', key: key, dangerouslySetInnerHTML:{__html: node.value}
    else
      # console.log node
      throw node.type +' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

module.exports = (raw, _sanitize = true) ->
  sanitize = _sanitize
  ast = mdast.parse raw
  compile(ast)
