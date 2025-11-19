import { BarChart3 } from 'lucide-react'

export default function Stats({ userSession }: { userSession: any }) {
  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold text-white mb-2">Statistics</h2>
        <p className="text-slate-400">Platform-wide carbon offset metrics</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card">
          <p className="text-sm text-slate-400 mb-2">Total Projects</p>
          <p className="text-4xl font-bold text-white">0</p>
        </div>
        <div className="card">
          <p className="text-sm text-slate-400 mb-2">Total Tokens Minted</p>
          <p className="text-4xl font-bold text-white">0</p>
        </div>
        <div className="card">
          <p className="text-sm text-slate-400 mb-2">Total Retired</p>
          <p className="text-4xl font-bold text-white">0 tons</p>
        </div>
      </div>

      <div className="card text-center py-16">
        <BarChart3 className="w-16 h-16 mx-auto mb-4 text-slate-600" />
        <h3 className="text-xl font-semibold text-white mb-2">Analytics Coming Soon</h3>
        <p className="text-slate-400">
          Detailed charts and insights will be available once projects are created
        </p>
      </div>
    </div>
  )
}
