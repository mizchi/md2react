should = chai.should()
global.React = require 'react'
md2react = require '../src/index'

options = gfm: true, breaks: true, tasklist: true

describe 'text', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react 'foo', options
      .should.equal '<div><p>foo</p></div>'

describe 'escape', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '\\', options
      .should.equal '<div><p>\\</p></div>'

describe 'break', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
      foo
      bar
      baz
      '''
    , options
      .should.equal '<div><p>foo<br>bar<br>baz</p></div>'

describe 'horizontalRule', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    ---
    ''', options
      .should.equal '<div><hr></div>'

describe 'image', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    ![image](http://example.com/image.png)
    ''', options
      .should.equal '<div><p><img src="http://example.com/image.png" alt="image"></p></div>'

describe 'inlineCode', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    `var a = 100;`
    ''', options
      .should.equal '<div><p><code class="inlineCode">var a = 100;</code></p></div>'

describe 'code', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    ```
    var a = 100;
    var b = 200;

    var c = 300;
    ```
    ''', options
      .should.equal '<div><pre class="code"><code>var a = 100;\nvar b = 200;\n\nvar c = 300;</code></pre></div>'

describe 'root', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '', options
      .should.equal '<div></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '', options
      .should.equal '<div></div>'

describe 'strong', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '**foo**', options
      .should.equal '<div><p><strong>foo</strong></p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '**foo~~bar~~baz**', options
      .should.equal '<div><p><strong>foo<s>bar</s>baz</strong></p></div>'

describe 'emphasis', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '*foo*', options
      .should.equal '<div><p><em>foo</em></p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '*foo~~bar~~baz*', options
      .should.equal '<div><p><em>foo<s>bar</s>baz</em></p></div>'

describe 'delete', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '~~foo~~', options
      .should.equal '<div><p><s>foo</s></p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '~~foo**bar**baz~~', options
      .should.equal '<div><p><s>foo<strong>bar</strong>baz</s></p></div>'

describe 'paragraph', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react 'foo', options
      .should.equal '<div><p>foo</p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react 'foo', options
      .should.equal '<div><p>foo</p></div>'

describe 'link', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '[foo](http://example.com)', options
      .should.equal '<div><p><a href="http://example.com">foo</a></p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '[foo**bar**baz](http://example.com)', options
      .should.equal '<div><p><a href="http://example.com">foo<strong>bar</strong>baz</a></p></div>'

describe 'heading', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    # heading1
    ## heading2
    ### heading3
    #### heading4
    ##### heading5
    ###### heading6
    ''', options
      .should.equal '<div><h1>heading1</h1><h2>heading2</h2><h3>heading3</h3><h4>heading4</h4><h5>heading5</h5><h6>heading6</h6></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '''
    # foo**bar**baz
    ## foo**bar**baz
    ### foo**bar**baz
    #### foo**bar**baz
    ##### foo**bar**baz
    ###### foo**bar**baz
    ''', options
      .should.equal '<div><h1>foo<strong>bar</strong>baz</h1><h2>foo<strong>bar</strong>baz</h2><h3>foo<strong>bar</strong>baz</h3><h4>foo<strong>bar</strong>baz</h4><h5>foo<strong>bar</strong>baz</h5><h6>foo<strong>bar</strong>baz</h6></div>'

describe 'list', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    - foo
    - [ ] bar
    - [x] baz
    1. foo
    1. bar
    1. baz
    ''', options
      .should.equal '<div><ul><li class=""><p>foo</p></li><li class="unchecked"><p>bar</p></li><li class="checked"><p>baz</p></li></ul><ol><li class=""><p>foo</p></li><li class=""><p>bar</p></li><li class=""><p>baz</p></li></ol></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '''
    - foo**bar**baz
    - [ ] bar*baz*qux
    - [x] bar~~qux~~quux
    1. foo**bar**baz
    1. bar*baz*qux
    1. bar~~qux~~quux
    ''', options
      .should.equal '<div><ul><li class=""><p>foo<strong>bar</strong>baz</p></li><li class="unchecked"><p>bar<em>baz</em>qux</p></li><li class="checked"><p>bar<s>qux</s>quux</p></li></ul><ol><li class=""><p>foo<strong>bar</strong>baz</p></li><li class=""><p>bar<em>baz</em>qux</p></li><li class=""><p>bar<s>qux</s>quux</p></li></ol></div>'

describe 'blockquote', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    > foo
    bar
    baz
    ''', options
      .should.equal '<div><blockquote><p>foo<br>bar<br>baz</p></blockquote></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '''
    > foo**bar**baz
    bar*baz*qux
    baz~~qux~~quux
    ''', options
      .should.equal '<div><blockquote><p>foo<strong>bar</strong>baz<br>bar<em>baz</em>qux<br>baz<s>qux</s>quux</p></blockquote></div>'

describe 'linkReference', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    [foo][Example]
    [bar][example]
    [Example]
    [example]: http://example.com
    ''', options
      .should.equal '<div><p><a href="http://example.com">foo</a><br><a href="http://example.com">bar</a><br><a href="http://example.com">Example</a></p></div>'

  it 'should be compiled when node has children', ->
    React.renderToStaticMarkup md2react '''
    [foo**bar**baz][Example]
    [foo**bar**baz][example]
    [Example]
    [example]: http://example.com
    ''', options
      .should.equal '<div><p><a href="http://example.com">foo<strong>bar</strong>baz</a><br><a href="http://example.com">foo<strong>bar</strong>baz</a><br><a href="http://example.com">Example</a></p></div>'

describe 'table', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    | foo | bar | baz |
    |:----|:---:|----:|
    |  1  |  2  |  3  |
    ''', options
      .should.equal '<div><table><thead><tr><th style="text-align:left;">foo</th><th style="text-align:center;">bar</th><th style="text-align:right;">baz</th></tr></thead><tbody><tr><td style="text-align:left;">1</td><td style="text-align:center;">2</td><td style="text-align:right;">3</td></tr></tbody></table></div>'

describe 'html', ->

  it 'should be compiled', ->
    React.renderToStaticMarkup md2react '''
    <span>foo</span>
    ''', options
      .should.equal '<div><p><span>foo</span></p></div>'

describe 'complex', ->

  it 'should be compiled', ->
    md = '''
# Hello
hello

- a
- b

----

- [ ] unchecked
- [x] checked
- plain

-------

1. 1
2. 2

-------

- [x] a
- [ ] b
- c

------

`a`

~~striked~~


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

-
  loose

- item

'''
    element = md2react md, gfm: true, breaks: true, tasklist: true
    React.renderToStaticMarkup element
      .should.equal '<div><h1>Hello</h1><p>hello</p><ul><li class=""><p>a</p></li><li class=""><p>b</p></li></ul><hr><ul><li class="unchecked"><p>unchecked</p></li><li class="checked"><p>checked</p></li><li class=""><p>plain</p></li></ul><hr><ol><li class=""><p>1</p></li><li class=""><p>2</p></li></ol><hr><ul><li class="checked"><p>a</p></li><li class="unchecked"><p>b</p></li><li class=""><p>c</p></li></ul><hr><p><code class="inlineCode">a</code></p><p><s>striked</s></p><p><span></span></p><pre class="code"><code>bbb</code></pre><p><strong>AA</strong></p><p><em>BB</em></p><p><a href="/foo">foo</a></p><p><img src="/img.png" alt="img"></p><blockquote><p>aaa<br>bbb</p></blockquote><table><thead><tr><th style="text-align:left;">TH</th><th style="text-align:left;">TH</th></tr></thead><tbody><tr><td style="text-align:left;">TD</td><td style="text-align:left;">TD</td></tr></tbody><tbody><tr><td style="text-align:left;">TD</td><td style="text-align:left;">TD</td></tr></tbody></table><p>-<br>  loose</p><ul><li class=""><p>item</p></li></ul></div>'
