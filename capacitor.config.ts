import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.tzbfire.clawbenchios',
  appName: 'ClawBench',
  webDir: 'www',
  bundledWebRuntime: false,
  ios: {
    contentInset: 'automatic',
    allowsLinkPreview: true,
    scrollEnabled: true,
    backgroundColor: '#0d1117'
  },
  server: {
    cleartext: true,
    allowNavigation: ['*']
  },
  plugins: {
    SplashScreen: {
      launchAutoHide: true,
      backgroundColor: '#0d1117',
      showSpinner: false
    }
  }
}

export default config
