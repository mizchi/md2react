# md2react

```
npm install --save md2react
```

See [md2react playground](http://mizchi.github.io/md2react/ "md2react playground")

Not well tested yet.

## TODO

- Raw html causes react violation in dangerouslySetInnerHTML
- Tests

## Example

```javascript
global.React = require('react');
var md2react = require('md2react');

var md = '# Hello';
var html = React.renderToString(md2react(md));
//'<div data-reactid=".58nba97pxc" data-react-checksum="-55236619"><h1 data-reactid=".58nba97pxc.0"><span data-reactid=".58nba97pxc.0.0">Hello</span></h1></div>'
```

## LICENSE

MIT
