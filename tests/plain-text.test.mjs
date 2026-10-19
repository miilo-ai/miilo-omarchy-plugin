import fs from 'node:fs';
import {test} from 'node:test';
import assert from 'node:assert/strict';
import path from 'node:path';
const root=path.resolve(import.meta.dirname,'..');
for(const file of ['OwlNode.qml','OwlTerminal.qml'])test(file+' uses explicit plain text for every Text item',()=>{
 const source=fs.readFileSync(path.join(root,'vendor/owl',file),'utf8');
 const blocks=[...source.matchAll(/\bText\s*\{([\s\S]*?)^\s*\}/gm)];
 assert(blocks.length>=3,'Expected runtime text surfaces');
 for(const block of blocks)assert.match(block[1],/textFormat:\s*Text\.PlainText/,'Implicit rich-text detection in '+file);
});
