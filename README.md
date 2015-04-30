# md2react

```
npm install --save md2react
```

See [md2react playground](http://mizchi.github.io/md2react/ "md2react playground")

## Example

```javascript
global.React = require('react');
var md2react = require('md2react');

var md = '# Hello md2react';
var html = React.renderToString(md2react(md));

/*
<div data-reactid=".14qrwokr3sw" data-react-checksum="20987480"><h1 data-reactid=".14qrwokr3sw.$_start_root_0_heading"><span data-reactid=".14qrwokr3sw.$_start_root_0_heading.0">Hello md2react</span></h1></div>'
//'<div data-reactid=".58nba97pxc" data-react-checksum="-55236619"><h1 data-reactid=".58nba97pxc.0"><span data-reactid=".58nba97pxc.0.0">Hello</span></h1></div>'
*/
```

## Checklist

Compiled elements are given checked/unchecked class if bullet has checkbox.

```javascript
var md = '- [x] a\n- [ ] b\n- c';
var html = React.renderToString(md2react(md, tasklist: true));
```

```html
<div><ul><li class="checked"><p>a</p></li><li class="unchecked"><p>b</p></li><li class=""><p>c</p></li></ul></div>
```

Write your checklist style

## API

- `md2react(markdown: string , mdastOptionsWithSanitize: Object): ReactElement`

See mdast detail in [wooorm/mdast](https://github.com/wooorm/mdast "wooorm/mdast")

And `sanitize: true` uses dompurify to raw html input(examle, `<span onload='alert(1)'></span>`)

## ChangeLog

### v0.5.1

- Support table align

### v0.5.0

- Update mdast to 0.12.0
- Fix table align

## LICENSE

MIT
