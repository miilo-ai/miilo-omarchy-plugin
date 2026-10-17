import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import assert from 'node:assert/strict';
import checker from '../tools/lib/package-check.cjs';
const source=path.resolve(import.meta.dirname,'..');
function fixture(t){const root=fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(),'miilo-package-')));t.after(()=>fs.rmSync(root,{recursive:true,force:true}));for(const name of ['manifest.json','sources.lock.json','LICENSE','ui','vendor','assets','patches'])if(fs.existsSync(path.join(source,name)))fs.cpSync(path.join(source,name),path.join(root,name),{recursive:true});return root;}
function manifest(root,mutate){const file=path.join(root,'manifest.json'),value=JSON.parse(fs.readFileSync(file,'utf8'));mutate(value);fs.writeFileSync(file,JSON.stringify(value));}
test('valid package passes',t=>assert.doesNotThrow(()=>checker.check(fixture(t))));
test('entry cannot escape',t=>{const root=fixture(t);manifest(root,m=>m.entryPoints.barWidget='../secret.qml');assert.throws(()=>checker.check(root),/Unsafe/);});
test('missing entry fails',t=>{const root=fixture(t);manifest(root,m=>m.entryPoints.barWidget='Missing.qml');assert.throws(()=>checker.check(root),/Missing file/);});
test('symlink dependency fails',t=>{const root=fixture(t);fs.symlinkSync(os.tmpdir(),path.join(root,'vendor/secret'));assert.throws(()=>checker.check(root),/Symlink/);});
test('vendor drift fails',t=>{const root=fixture(t);fs.appendFileSync(path.join(root,'vendor/owl/OwlWidget.qml'),'\n// drift\n');assert.throws(()=>checker.check(root),/Unreviewed source drift/);});
test('missing license fails',t=>{const root=fixture(t);fs.unlinkSync(path.join(root,'vendor/owl/LICENSE'));assert.throws(()=>checker.check(root),/Missing file/);});
test('untracked vendor file fails',t=>{const root=fixture(t);fs.writeFileSync(path.join(root,'vendor/Hidden.qml'),'import QtQuick\nItem{}');assert.throws(()=>checker.check(root),/Unpinned runtime asset/);});
