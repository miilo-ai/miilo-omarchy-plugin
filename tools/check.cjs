const path=require('node:path');
const {check}=require('./lib/package-check.cjs');
try {
  check(path.resolve(__dirname,'..'));
  console.log('Manifest, imports, source hashes, licenses and single-shell source checks passed.');
  console.log('Native Omarchy runtime acceptance remains a separate gate.');
} catch(error) {console.error(error.message);process.exitCode=1;}
