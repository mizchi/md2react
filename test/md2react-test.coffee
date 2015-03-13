global.React = require 'react'
md2react = require '../src/index'

md = '''
# Hello
hello

- a
- b

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
console.log React.renderToStaticMarkup element
