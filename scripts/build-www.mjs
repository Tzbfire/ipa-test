import { mkdirSync, copyFileSync, existsSync } from 'node:fs'
import { join } from 'node:path'

mkdirSync('www', { recursive: true })
mkdirSync('www/assets', { recursive: true })

const candidates = [
  ['assets/logo.png', 'www/assets/logo.png'],
  ['assets/favicon.png', 'www/assets/favicon.png']
]

for (const [src, dst] of candidates) {
  if (existsSync(src)) copyFileSync(src, dst)
}

console.log('www prepared at', join(process.cwd(), 'www'))
