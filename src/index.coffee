mdast = require 'mdast'
uuid = require 'uuid'

$ = React.createElement
defaultHTMLWrapper = React.createClass
  _update: ->
    current = @props.html
    if @_lastHtml isnt current
      @_lastHtml = current
      node = @refs.htmlWrapper.getDOMNode()
      node.contentDocument.body.innerHTML = @props.html
      node.style.height = node.contentWindow.document.body.scrollHeight + 'px'
      node.style.width  = node.contentWindow.document.body.scrollWidth  + 'px'

  componentDidUpdate: -> @_update()
  componentDidMount: -> @_update()

  render: ->
    $ 'iframe',
      ref: 'htmlWrapper'
      html: @props.html
      style:
        border: 'none'

toChildren = (node, parentKey, tableAlign = []) ->
  return (for child, i in node.children
    compile(child, parentKey+'_'+i, tableAlign))

parser = new DOMParser()
isInvalidXML = (xmlString) ->
  parsererrorNS = parser.parseFromString('INVALID', 'text/xml').getElementsByTagName("parsererror")[0].namespaceURI
  dom = parser.parseFromString(xmlString, 'text/xml')

  if dom.getElementsByTagNameNS(parsererrorNS, 'parsererror').length > 0
    throw new Error('Error parsing XML')
  return dom;


# Override by option
sanitize = null
highlight = null

compile = (node, parentKey='_start', tableAlign = null) ->
  key = parentKey+'_'+node.type

  switch node.type
    # No child
    when 'text'           then node.value
    when 'escape'         then '\\'
    when 'break'          then $ 'br', {key}
    when 'horizontalRule' then $ 'hr', {key}
    when 'image'          then $ 'img', {key, src: node.src, title: node.title, alt: node.alt}
    when 'inlineCode'     then $ 'code', {key, className:'inlineCode'}, node.value
    when 'code'           then highlight node.value, node.lang

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
          $ 'th', {key: k, style: {textAlign: tableAlign[i] ? 'left'}}, toChildren(cell, k)
      ]

    when 'tableRow'
      # $ 'tr', {key}  , [$ 'td', {key: key+'_inner-td'}, toChildren(node, key)]
      $ 'tbody', {key}, [
        $ 'tr', {key: key+'-_inner-td'}, node.children.map (cell, i) ->
          k = key+'-td'+i
          $ 'td', {key: k, style: {textAlign: tableAlign[i] ? 'left'}}, toChildren(cell, k)
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
      $ htmlWrapperComponent, key: key, html: value
    else
      throw node.type + ' is unsuppoted node type. report to https://github.com/mizchi/md2react/issues'

htmlWrapperComponent = null
module.exports = (raw, options = {}) ->
  htmlWrapperComponent = options.htmlWrapperComponent ? defaultHTMLWrapper
  sanitize = options.sanitize ? true
  highlight = options.highlight ? (code, lang) ->
    $ 'pre', {key, className: 'code'}, [
      $ 'code', {key: key+'-_inner-code'}, code
    ]
  ast = mdast.parse raw, options
  compile(ast)
