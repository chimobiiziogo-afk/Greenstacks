import { Plus, MapPin } from 'lucide-react'

export default function Projects({ userSession }: { userSession: any }) {
  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-white mb-2">Carbon Projects</h2>
          <p className="text-slate-400">Manage and create carbon offset projects</p>
        </div>
        <button className="btn-primary flex items-center space-x-2">
          <Plus className="w-4 h-4" />
          <span>Create Project</span>
        </button>
      </div>

      <div className="card text-center py-16">
        <MapPin className="w-16 h-16 mx-auto mb-4 text-slate-600" />
        <h3 className="text-xl font-semibold text-white mb-2">No Projects Yet</h3>
        <p className="text-slate-400 mb-6">
          Create your first carbon offset project to start issuing credits
        </p>
        <button className="btn-primary">Get Started</button>
      </div>
    </div>
  )
}
