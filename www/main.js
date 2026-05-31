import { Preferences } from '@capacitor/preferences'
import { Capacitor, registerPlugin } from '@capacitor/core'

const NativeBridge = registerPlugin('ClawBenchBridge')
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

function installAndroidNativeCompat(serverUrl) {
  if (!Capacitor.isNativePlatform()) return
  if (window.AndroidNative) return

  window.AndroidNative = {
    isNativeApp() { return true },
    isIOSApp() { return true },
    isAndroidApp() { return false },
    getPassword() { return localStorage.getItem('clawbench.sshPassword') || '' },
    setSSHPassword(password) { localStorage.setItem('clawbench.sshPassword', String(password || '')) },
    getPendingNavigation() { return '' },
    isPushAvailable() { return false },
    getPushRegistrationId() { return '' },
    startLogCapture() {},
    stopLogCapture() {},
    setVolumeKeyMode() {},
    async showServerDialog() { await NativeBridge.showServerDialog() },
    async addForwardedPort(localPort, targetPort, host) {
      await NativeBridge.addForwardedPort({ localPort, targetPort, host: host || '' })
      window.dispatchEvent(new CustomEvent('clawbench-port-forward-result', { detail: { localPort, success: true } }))
    },
    async removeForwardedPort(localPort) { await NativeBridge.removeForwardedPort({ localPort }) },
    async stopBackgroundService() { await NativeBridge.stopBackgroundService() },
    reconnectTunnel() { NativeBridge.reconnectTunnel(); return true },
    testPortReachable(localPort) { return true },
    async openInBrowser(port, protocol, host) {
      const url = buildLocalUrl(port, protocol)
      await NativeBridge.openInBrowser({ url, port, protocol, host: host || '' })
    },
    async openInSandbox(port, protocol, host) {
      const url = buildLocalUrl(port, protocol)
      await NativeBridge.openInSandbox({ url, port, protocol, host: host || '' })
    },
    async downloadFile(path) { await NativeBridge.downloadFile({ path }) }
  }
}

function buildLocalUrl(port, protocol) {
  const scheme = protocol === 'https' ? 'https' : 'http'
  return `${scheme}://127.0.0.1:${encodeURIComponent(port)}`
}

async function connect(raw) {
  clearError()
  const url = normalizeUrl(raw)
  if (!url) {
    showError('地址无效，请输入 http://服务器IP:20000 或 https://你的域名')
    return
  }
  await Preferences.set({ key: KEY, value: url })
  localStorage.setItem(KEY, url)
  installAndroidNativeCompat(url)
  window.location.href = url
}

connectBtn.addEventListener('click', () => connect(input.value))
input.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') connect(input.value)
})
clearBtn.addEventListener('click', async () => {
  await Preferences.remove({ key: KEY })
  localStorage.removeItem(KEY)
  input.value = ''
  clearError()
})

const saved = await Preferences.get({ key: KEY })
if (saved.value) {
  input.value = saved.value
  installAndroidNativeCompat(saved.value)
  if (Capacitor.isNativePlatform()) {
    setTimeout(() => connect(saved.value), 250)
  }
}
