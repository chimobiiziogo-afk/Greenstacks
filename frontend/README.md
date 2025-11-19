# GreenStacks Frontend

Modern, responsive web dashboard for the GreenStacks carbon offset marketplace built with React, TypeScript, and TailwindCSS.

## Features

- **Wallet Integration**: Connect with Stacks wallets using @stacks/connect
- **Dashboard**: Overview of carbon token portfolio and recent activity
- **Marketplace**: Browse and purchase verified carbon credits
- **Projects**: Manage and create carbon offset projects
- **Statistics**: Platform-wide metrics and analytics
- **Modern UI**: Beautiful, responsive design with Tailwind CSS
- **Type Safety**: Full TypeScript support

## Tech Stack

- **React 18**: Modern React with hooks
- **TypeScript**: Type-safe development
- **Vite**: Fast build tool and dev server
- **TailwindCSS**: Utility-first CSS framework
- **Lucide React**: Beautiful icon library
- **@stacks/connect**: Stacks wallet integration
- **@stacks/transactions**: Stacks blockchain interactions

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- A Stacks wallet (Hiro Wallet recommended)

### Installation

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The application will be available at `http://localhost:3000`

### Build for Production

```bash
npm run build
npm run preview
```

## Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   ├── Dashboard.tsx    # Main dashboard view
│   │   ├── Marketplace.tsx  # Carbon credit marketplace
│   │   ├── Projects.tsx     # Project management
│   │   └── Stats.tsx        # Statistics and analytics
│   ├── App.tsx              # Main application component
│   ├── main.tsx             # Application entry point
│   └── index.css            # Global styles and Tailwind
├── index.html
├── package.json
├── tailwind.config.js
├── tsconfig.json
└── vite.config.ts
```

## Features Overview

### Dashboard
- Portfolio overview with key metrics
- Recent activity feed
- Quick action cards for common tasks
- Real-time token balance display

### Marketplace
- Browse available carbon credit listings
- Filter and search functionality
- Purchase verified carbon tokens
- View project details and verification status

### Projects
- Create new carbon offset projects
- Manage existing projects
- Track project verification status
- Monitor credit issuance

### Statistics
- Platform-wide metrics
- Total projects and tokens minted
- Retirement tracking
- Visual analytics (coming soon)

## Wallet Integration

The app uses @stacks/connect for seamless wallet integration:

1. Click "Connect Wallet" in the header
2. Choose your Stacks wallet
3. Approve the connection
4. Start interacting with the platform

## Customization

### Theme Colors

Edit `tailwind.config.js` to customize the color scheme:

```javascript
theme: {
  extend: {
    colors: {
      primary: {
        // Your custom colors
      },
    },
  },
}
```

### Component Styling

Components use Tailwind utility classes. Custom styles are defined in `src/index.css`.

## Development

### Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

### Code Style

- TypeScript for type safety
- Functional components with hooks
- Tailwind CSS for styling
- Lucide React for icons

## Integration with Smart Contract

The frontend is designed to interact with the GreenStacks smart contract:

- Create and verify projects
- Mint and transfer tokens
- List tokens on marketplace
- Retire tokens for carbon offsetting
- View audit trails and statistics

## Browser Support

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues or questions:
- GitHub Issues: [Report a bug]
- Documentation: [View docs]
- Community: [Join Discord]

## Roadmap

- [ ] Real-time contract interaction
- [ ] Advanced filtering and search
- [ ] Project creation wizard
- [ ] Retirement certificate generation
- [ ] Analytics dashboard with charts
- [ ] Mobile app version
- [ ] Multi-language support

---

Built with ❤️ for a sustainable future
