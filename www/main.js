import { Preferences } from '@capacitor/preferences'
import { Capacitor } from '@capacitor/core'

const KEY = 'clawbench.serverUrl'
const input = document.querySelector('#serverUrl')
const connectBtn = document.querySelector('#connectBtn')
const clearBtn = document.querySelector('#demoBtn')
const errorEl = document.querySelector('#error')

function showError(message) {
  errorEl.textContent = message
  errorEl.hidden = false
}

function clearError() {
  errorEl.hidden = true
  errorEl.textContent = ''
}

function normalizeUrl(raw) {
  let value = String(raw || '').trim()
  if (!value) return null
  if (!value.includes('://')) value = 'http://' + value
  let url
  try { url = new URL(value) } catch { return null }
  if (!['http:', 'https:'].includes(url.protocol)) return null
  url.hash = ''
  if (url.pathname === '/') url.pathname = ''
  return url.toString().replace(/\/$/, '')
}

async function connect(raw) {
  clearError()
  const url = normalizeUrl(raw)
  if (!url) {
    showError('地址无效，请输入 http://服务器IP:20000 或 https://你的域名')
    return
  }
  await Preferences.set({ key: KEY, value: url })

  // 直接在 Capacitor 主 WKWebView 内导航到 ClawBench 服务端。
  // 这样远程 ClawBench Web UI 会像 Android WebView 一样运行在 App 内，
  // 后续可通过 Capacitor 插件继续补 SSH 隧道、下载、沙盒浏览等原生能力。
  window.location.href = url
}

connectBtn.addEventListener('click', () => connect(input.value))
input.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') connect(input.value)
})
clearBtn.addEventListener('click', async () => {
  await Preferences.remove({ key: KEY })
  input.value = ''
  clearError()
})

const saved = await Preferences.get({ key: KEY })
if (saved.value) {
  input.value = saved.value
  if (Capacitor.isNativePlatform()) {
    setTimeout(() => connect(saved.value), 250)
  }
}
