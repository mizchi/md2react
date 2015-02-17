mdast = require 'mdast'
$ = React.createElement
compile = ->
  switch node.type
    when 'root'
      $ 'div', {}, (compile(child) for child in node.children)
    when 'text'
      node.text
    when 'strong'
      $ 'strong', {}, (compile(child) for child in node.children)
    when 'emphasis'
      $ 'em', {}, (compile(child) for child in node.children)
    when 'horizontalRule'
      $ 'hr'
    when 'inlineCode'
      # TODO: code is valide?
      $ 'code', {}, [node.value]
    when 'code'
      # TODO: code is valide?
      $ 'code', {}, [node.value]
    when 'heading'
      tag = 'h'+node.depth.toString()
      $ tag, {}, (compile(child) for child in node.children)
    when 'paragraph'
      $ 'p', {}, (compile(child) for child in node.children)
    when 'list'
      tag = if node.ordered then 'ol' else 'ul'
      $ tag, {}, (compile(child) for child in node.children)
    when 'link'
      $ 'a', {href: node.href, title: node.title}, (compile(child) for child in node.children)
    when 'image'
      $ 'img', {src: node.src, title: node.title, alt: node.alt}
    when 'blockquote'
      $ 'blockquote', {}, (compile(child) for child in node.children)
    when 'table'
      # TODO: fixme
      $ 'table', {}, (compile(child) for child in node.children)
    when 'tableHeader'
      $ 'tr', {}, (($ 'tr', {}, compile(child)) for child in node.children)
    when 'tableRow'
      $ 'tr', {}, (($ 'td', {}, compile(child)) for child in node.children)
    when 'tableCell'
      $ 'span', {}, (compile(child) for child in node.children)
    when 'listItem'
      # TODO: what is loose property?
      $ 'li', {}, (compile(child) for child in node.children)
    when 'html'
      $ 'div', dangerouslySetInnerHTML:{__html: node.value}
    else
      console.log 'unknown node type:', node.type
      console.log node
      throw 'stop'

module.exports = compile = (node) ->
  switch node.type
    when 'root'
      $ 'div', {}, (compile(child) for child in node.children)
    when 'text'
      node.text
    when 'strong'
      $ 'strong', {}, (compile(child) for child in node.children)
    when 'emphasis'
      $ 'em', {}, (compile(child) for child in node.children)
    when 'horizontalRule'
      $ 'hr'
    when 'inlineCode'
      # TODO: code is valide?
      $ 'code', {}, [node.value]
    when 'code'
      # TODO: code is valide?
      $ 'code', {}, [node.value]
    when 'heading'
      tag = 'h'+node.depth.toString()
      $ tag, {}, (compile(child) for child in node.children)
    when 'paragraph'
      $ 'p', {}, (compile(child) for child in node.children)
    when 'list'
      tag = if node.ordered then 'ol' else 'ul'
      $ tag, {}, (compile(child) for child in node.children)
    when 'link'
      $ 'a', {href: node.href, title: node.title}, (compile(child) for child in node.children)
    when 'image'
      $ 'img', {src: node.src, title: node.title, alt: node.alt}
    when 'blockquote'
      $ 'blockquote', {}, (compile(child) for child in node.children)
    when 'table'
      # TODO: fixme
      $ 'table', {}, (compile(child) for child in node.children)
    when 'tableHeader'
      $ 'tr', {}, (($ 'tr', {}, compile(child)) for child in node.children)
    when 'tableRow'
      $ 'tr', {}, (($ 'td', {}, compile(child)) for child in node.children)
    when 'tableCell'
      $ 'span', {}, (compile(child) for child in node.children)
    when 'listItem'
      # TODO: what is loose property?
      $ 'li', {}, (compile(child) for child in node.children)
    when 'html'
      $ 'div', dangerouslySetInnerHTML:{__html: node.value}
    else
      console.log 'unknown node type:', node.type
      console.log node
      throw 'stop'

module.exports = (raw) ->
  ast = mdast.parse raw
  compile(ast)
