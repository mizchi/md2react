global.React = require 'react'
md2react = require '../src/index'

md = '''
# foo
hello
'''

'''
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

-
  loose

- item

'''

element = md2react md, gfm: true, breaks: true
# element = md2react md

# console.log React.renderToStaticMarkup element
console.log React.renderToString element
