import { ShoppingCart, Filter } from 'lucide-react'

interface MarketplaceProps {
  userSession: any
}

export default function Marketplace({ userSession }: MarketplaceProps) {
  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold text-white mb-2">Marketplace</h2>
          <p className="text-slate-400">Browse and purchase verified carbon credits</p>
        </div>
        <button className="btn-primary flex items-center space-x-2">
          <Filter className="w-4 h-4" />
          <span>Filters</span>
        </button>
      </div>

      <div className="card text-center py-16">
        <ShoppingCart className="w-16 h-16 mx-auto mb-4 text-slate-600" />
        <h3 className="text-xl font-semibold text-white mb-2">No Listings Available</h3>
        <p className="text-slate-400 mb-6">
          Be the first to list carbon credits on the marketplace
        </p>
        <button className="btn-primary">Create Listing</button>
      </div>
    </div>
  )
}
