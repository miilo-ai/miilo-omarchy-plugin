const path=require('node:path');
const {runPreview}=require('./lib/qt-preview.cjs');
const root=path.resolve(__dirname,'..');
try {runPreview(root,'crew',process.argv[2]||'/tmp/miilo-crew-preview',()=>({fixture:path.join(root,'tests/qml/CrewFixture.qml')}));}
catch(error){console.error('Native Qt crew preview failed: '+error.message);process.exitCode=1;}
