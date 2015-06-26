global.React = require('react')
md2react = require('../src/index')

$ = React.createElement

defaultMarkdown = '''
# Hello

body

1. 1
2. 2

------

- [ ] unchecked
- [x] checked
- foo

`a`

------

```
bbb
```

**AA**

*BB*

[foo](/foo)

![image](http://placehold.it/20x20/27709b/ffffff)

> aaa
> bbb

|  TH  |  TH  |
| ---- | ---- |
|  TD  |  TD  |
|  TD  |  TD  |
'''

defaultMarkdown = '''
```js
var x = 3;
```
'''

Editor = React.createClass
  update: ->
    editor = @refs.editor.getDOMNode()
    try
      content = md2react editor.value,
        gfm: true
        breaks: true
        tables: true
        commonmark: true
        footnotes: true
        # highlight: (code, lang, key) -> # custom highlighter
        #   "#{lang}: #{code}"
      @setState content: content
    catch e
      console.warn 'markdown parse error'

  componentDidMount: ->
    editor = @refs.editor.getDOMNode()
    editor.value = defaultMarkdown
    @update()

  getInitialState: -> {content: null}

  render: ->
    $ 'div', {key: 'root'}, [
      $ 'h1', {style: {textAlign: 'center', fontFamily: '"Poiret One", cursive', fontSize: '25px', height: '50px', lineHeight: '50px'}}, 'md2react playground'
      $ 'div', {key: 'layout', className: 'flex'}, [
        $ 'div', {key: 'editorContainer', style:{
          width: '50%', borderRight: '1px solid', borderColor: '#999', overflow: 'hidden'}
        }, [
          $ 'textarea', {
            ref:'editor'
            onChange: @update
            style: {height: '100%', width: '100%', border: 0, outline: 0, fontSize: '14px', padding: '5px', overflow: 'auto', fontFamily:'Consolas, Menlo, monospace', resize: 'none', background: 'transparent'}
          }
        ]
        $ 'div',{
          className: 'previewContainer',
          key: 'previewContainer',
          style: {
            width: '50%'
            overflow: 'auto'
            padding: '5px'
            fontFamily: "'Helvetica Neue', Helvetica"
          }
        }, if @state.content then [@state.content] else ''
      ]
      $ 'div', {width: '100%', style: {textAlign: 'center', marginTop: '10px'}}, [
        $ 'a', {href:'https://github.com/mizchi/md2react', style: {fontFamily: 'Helvetica Neue, Helvetica', fontSize: '17px'}}, '[Fork me on GitHub](mizchi/md2react)'
      ]
    ]

window.addEventListener 'DOMContentLoaded', ->
  React.render(React.createElement(Editor, {}), document.body)
