import { TrendingUp, Leaf, Award, BarChart3 } from 'lucide-react'

interface DashboardProps {
  userSession: any
}

export default function Dashboard({ userSession }: DashboardProps) {
  const stats = [
    { label: 'Total Carbon Tokens', value: '0', icon: Leaf, color: 'text-primary-500' },
    { label: 'Tokens Retired', value: '0', icon: Award, color: 'text-blue-500' },
    { label: 'Active Listings', value: '0', icon: TrendingUp, color: 'text-purple-500' },
    { label: 'Portfolio Value', value: '0 STX', icon: BarChart3, color: 'text-yellow-500' },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-3xl font-bold text-white mb-2">Dashboard</h2>
        <p className="text-slate-400">Overview of your carbon offset portfolio</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat) => (
          <div key={stat.label} className="card">
            <div className="flex items-center justify-between mb-4">
              <stat.icon className={`w-8 h-8 ${stat.color}`} />
            </div>
            <p className="text-3xl font-bold text-white mb-1">{stat.value}</p>
            <p className="text-sm text-slate-400">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="card">
        <h3 className="text-xl font-bold text-white mb-4">Recent Activity</h3>
        <div className="text-center py-12 text-slate-400">
          <Leaf className="w-16 h-16 mx-auto mb-4 opacity-50" />
          <p>No activity yet. Start by creating a project or purchasing carbon credits.</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="card hover:border-primary-500 cursor-pointer transition-colors">
          <Leaf className="w-12 h-12 text-primary-500 mb-4" />
          <h3 className="text-lg font-semibold text-white mb-2">Create Project</h3>
          <p className="text-sm text-slate-400">Register a new carbon offset project</p>
        </div>
        
        <div className="card hover:border-primary-500 cursor-pointer transition-colors">
          <TrendingUp className="w-12 h-12 text-blue-500 mb-4" />
          <h3 className="text-lg font-semibold text-white mb-2">Browse Marketplace</h3>
          <p className="text-sm text-slate-400">Buy verified carbon credits</p>
        </div>
        
        <div className="card hover:border-primary-500 cursor-pointer transition-colors">
          <Award className="w-12 h-12 text-purple-500 mb-4" />
          <h3 className="text-lg font-semibold text-white mb-2">Retire Tokens</h3>
          <p className="text-sm text-slate-400">Offset your carbon footprint</p>
        </div>
      </div>
    </div>
  )
}
