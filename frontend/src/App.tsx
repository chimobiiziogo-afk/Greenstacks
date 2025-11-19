import { useState } from 'react'
import { AppConfig, UserSession, showConnect } from '@stacks/connect'
import { Leaf, TrendingUp, Shield, Award } from 'lucide-react'
import Dashboard from './components/Dashboard'
import Marketplace from './components/Marketplace'
import Projects from './components/Projects'
import Stats from './components/Stats'

const appConfig = new AppConfig(['store_write', 'publish_data'])
const userSession = new UserSession({ appConfig })

function App() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const [userData, setUserData] = useState<any>(null)

  const connectWallet = () => {
    showConnect({
      appDetails: {
        name: 'GreenStacks',
        icon: window.location.origin + '/logo.svg',
      },
      redirectTo: '/',
      onFinish: () => {
        const data = userSession.loadUserData()
        setUserData(data)
      },
      userSession,
    })
  }

  const disconnectWallet = () => {
    userSession.signUserOut()
    setUserData(null)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      {/* Header */}
      <header className="border-b border-slate-700 bg-slate-900/50 backdrop-blur-sm">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <Leaf className="w-8 h-8 text-primary-500" />
              <h1 className="text-2xl font-bold text-white">GreenStacks</h1>
              <span className="text-sm text-slate-400">Carbon Offset Marketplace</span>
            </div>
            
            <div className="flex items-center space-x-4">
              {userData ? (
                <>
                  <span className="text-sm text-slate-300">
                    {userData.profile.stxAddress.testnet.slice(0, 8)}...
                  </span>
                  <button onClick={disconnectWallet} className="btn-secondary">
                    Disconnect
                  </button>
                </>
              ) : (
                <button onClick={connectWallet} className="btn-primary">
                  Connect Wallet
                </button>
              )}
            </div>
          </div>
        </div>
      </header>

      {/* Navigation */}
      <nav className="border-b border-slate-700 bg-slate-900/30">
        <div className="container mx-auto px-4">
          <div className="flex space-x-8">
            {[
              { id: 'dashboard', label: 'Dashboard', icon: TrendingUp },
              { id: 'marketplace', label: 'Marketplace', icon: Award },
              { id: 'projects', label: 'Projects', icon: Shield },
              { id: 'stats', label: 'Statistics', icon: TrendingUp },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-2 py-4 px-2 border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-primary-500 text-primary-500'
                    : 'border-transparent text-slate-400 hover:text-slate-300'
                }`}
              >
                <tab.icon className="w-4 h-4" />
                <span className="font-medium">{tab.label}</span>
              </button>
            ))}
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {!userData ? (
          <div className="flex flex-col items-center justify-center min-h-[60vh] text-center">
            <Leaf className="w-24 h-24 text-primary-500 mb-6" />
            <h2 className="text-3xl font-bold text-white mb-4">
              Welcome to GreenStacks
            </h2>
            <p className="text-slate-400 mb-8 max-w-md">
              The decentralized carbon offset marketplace powered by Stacks blockchain.
              Connect your wallet to start trading verified carbon credits.
            </p>
            <button onClick={connectWallet} className="btn-primary text-lg px-8 py-3">
              Connect Wallet to Get Started
            </button>
          </div>
        ) : (
          <>
            {activeTab === 'dashboard' && <Dashboard userSession={userSession} />}
            {activeTab === 'marketplace' && <Marketplace userSession={userSession} />}
            {activeTab === 'projects' && <Projects userSession={userSession} />}
            {activeTab === 'stats' && <Stats userSession={userSession} />}
          </>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-700 bg-slate-900/50 mt-16">
        <div className="container mx-auto px-4 py-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div>
              <div className="flex items-center space-x-2 mb-4">
                <Leaf className="w-6 h-6 text-primary-500" />
                <span className="font-bold text-white">GreenStacks</span>
              </div>
              <p className="text-sm text-slate-400">
                Transparent, verified carbon offsets on the blockchain.
              </p>
            </div>
            
            <div>
              <h3 className="font-semibold text-white mb-4">Features</h3>
              <ul className="space-y-2 text-sm text-slate-400">
                <li>Verified Projects</li>
                <li>Transparent Trading</li>
                <li>Retirement Tracking</li>
                <li>Audit Trail</li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold text-white mb-4">Resources</h3>
              <ul className="space-y-2 text-sm text-slate-400">
                <li>Documentation</li>
                <li>Smart Contract</li>
                <li>GitHub</li>
                <li>Support</li>
              </ul>
            </div>
            
            <div>
              <h3 className="font-semibold text-white mb-4">Stats</h3>
              <ul className="space-y-2 text-sm text-slate-400">
                <li>Total Projects: 0</li>
                <li>Total Retired: 0 tons</li>
                <li>Active Listings: 0</li>
              </ul>
            </div>
          </div>
          
          <div className="border-t border-slate-700 mt-8 pt-8 text-center text-sm text-slate-400">
            <p>&copy; 2024 GreenStacks. Built on Stacks Blockchain.</p>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App
