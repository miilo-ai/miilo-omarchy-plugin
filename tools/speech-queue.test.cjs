const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const source=fs.readFileSync('ui/components/chat/SpeechQueue.js','utf8');
function queue(){const q={};vm.createContext(q);vm.runInContext(source,q);return q;}
test('delivers the first sentence before completion and retains split punctuation',()=>{
 const q=queue(),s=q.create();q.append(s,'First sentence.',false);assert.equal(s.queue.length,0);
 q.append(s,' Next sentence is',false);assert.equal(s.queue.shift(),'First sentence.');assert.equal(s.closed,false);
 q.append(s,' complete.',true);assert.equal(s.queue.shift(),'Next sentence is complete.');assert.equal(s.queue.length,0);
 assert.throws(()=>q.append(s,'late',true));
});
test('long unpunctuated text is bounded without losing words',()=>{
 const q=queue(),s=q.create(),text=Array(90).fill('word').join(' ');q.append(s,text,false);
 assert.ok(s.queue.length>0);q.append(s,'',true);assert.equal(s.queue.join(' '),text);
});
test('starts an unpunctuated first phrase sooner without dropping or reordering text',()=>{
 const q=queue(),s=q.create(),text=Array(35).fill('word').join(' ');
 q.append(s,text,false);assert.equal(s.queue.length,1);assert.ok(s.queue[0].length<=120);
 assert.equal(s.closed,false);q.append(s,'',true);assert.equal(s.queue.join(' '),text);
});
test('rejects oversized turns and unbounded pending speech',()=>{
 const q=queue(),s=q.create();assert.throws(()=>q.append(s,'a'.repeat(16001),true));
 assert.throws(()=>q.append(q.create(),'x'.repeat(241),false));
 assert.throws(()=>q.append(q.create(),'Sentence. '.repeat(65),false));
});
