global.React = require('react')
md2react = require('../lib/index')

$ = React.createElement

defaultMarkdown = '''
# Hello
hello

- a
- b

1. 1
2. 2

`a`

------

<span></span>

```
bbb
```

**AA**

*BB*

[foo](/foo)

![img](/img.png)

> aaa
> bbb


|  TH  |  TH  |
| ---- | ---- |
|  TD  |  TD  |
|  TD  |  TD  |
'''
Editor = React.createClass
  update: ->
    editor = @refs.editor.getDOMNode()
    @setState content: md2react editor.value

  componentDidMount: ->
    editor = @refs.editor.getDOMNode()
    editor.value = defaultMarkdown
    @update()

  getInitialState: -> {content: null}

  render: ->
    $ 'div', {key: 'root'}, [
      $ 'h1', {}, 'md2react playground'
      $ 'a', {href:'https://github.com/mizchi/md2react'}, "mizchi/md2react"
      $ 'div', {key: 'layout', style: {height: '100%', width: '100%', display: 'flex'}}, [
        $ 'div', {key: 'editorContainer', style:{width: '50%'}}, [
          $ 'textarea', {
            ref:'editor'
            onChange: @update
            style: {height: '100%', width: '100%'}
          }
        ]
        $ 'preview',{key:'previewContainer', style: {width: '45%'}}, if @state.content then [@state.content] else ''
      ]
    ]

window.addEventListener 'DOMContentLoaded', ->
  React.render(React.createElement(Editor, {}), document.body)
