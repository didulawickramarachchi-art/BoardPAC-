/* global console, process */
import fs from 'node:fs'
import path from 'node:path'

const root=process.cwd()
const backend=path.resolve(root,'../../board-admin-backend/src/main/java/com/portSrilanka/board_admin_backend/controller')
const walk=(folder,extension)=>fs.readdirSync(folder,{withFileTypes:true}).flatMap(entry=>entry.isDirectory()?walk(path.join(folder,entry.name),extension):entry.name.endsWith(extension)?[path.join(folder,entry.name)]:[])
const normalize=value=>('/'+value.replace(/^\/api\/?/,'').replace(/^\//,'').replace(/\$\{[^}]+\}|\{[^}]+\}/g,'{param}').replace(/\?.*$/,'').replace(/\/+$/,'')).replace(/\/+/g,'/')
const backendRoutes=[]
for(const file of walk(backend,'.java')){
 const source=fs.readFileSync(file,'utf8');const base=source.match(/@RequestMapping\s*\(\s*"([^"]+)"/)?.[1]||''
 const regex=/@(Get|Post|Put|Delete|Patch)Mapping(?:\s*\(([\s\S]*?)\))?/g;let match
 while((match=regex.exec(source))){const route=match[2]?.match(/"([^"]*)"/)?.[1]||'';backendRoutes.push({method:match[1].toUpperCase(),path:normalize(`${base}/${route}`),file:path.basename(file)})}
}
const frontendRoutes=[]
for(const file of walk(path.join(root,'src'),'.js').concat(walk(path.join(root,'src'),'.jsx'))){
 const source=fs.readFileSync(file,'utf8');const regex=/api\.(get|post|put|delete|patch)\(\s*([`'"])(.*?)\2/g;let match
 while((match=regex.exec(source))) frontendRoutes.push({method:match[1].toUpperCase(),path:normalize(match[3]),file:path.relative(root,file)})
 const downloads=/downloadFile\(\s*([`'"])(.*?)\1/g
 while((match=downloads.exec(source))) frontendRoutes.push({method:'GET',path:normalize(match[2]),file:path.relative(root,file)})
}
const key=route=>`${route.method} ${route.path}`
const backendKeys=new Set(backendRoutes.map(key))
const unmatched=frontendRoutes.filter(route=>!backendKeys.has(key(route)))
const dynamic=unmatched.filter(route=>route.path.includes('{param}s')||route.path.startsWith('/{param}')||route.path==='/devices/{param}/{param}'||route.path==='/{param}/{param}')
const mismatched=unmatched.filter(route=>!dynamic.includes(route))
console.log(`Backend mappings: ${backendRoutes.length}`)
console.log(`Direct frontend calls: ${frontendRoutes.length}`)
if(mismatched.length){console.log('\nFrontend calls without a matching backend method/path:');for(const route of mismatched)console.log(`- ${key(route)} (${route.file})`);process.exitCode=1}else console.log('\nAll statically resolvable frontend API calls match backend controller mappings.')
if(dynamic.length){console.log('\nDynamic calls requiring finite-value review:');for(const route of dynamic)console.log(`- ${key(route)} (${route.file})`)}
