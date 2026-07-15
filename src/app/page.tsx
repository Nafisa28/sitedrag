import Link from 'next/link'

export default function Home() {
  return (
    <div className='min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950'>
      {/* Navbar */}
      <nav className='border-b border-slate-800 bg-slate-900/50 backdrop-blur-xl'>
        <div className='max-w-7xl mx-auto px-6 py-4 flex items-center justify-between'>
          <h1 className='text-2xl font-bold bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent'>
            DragSite
          </h1>
          <div className='flex items-center gap-4'>
            <Link
              href='/auth/login'
              className='px-4 py-2 text-slate-300 hover:text-white transition-colors'
            >
              Sign In
            </Link>
            <Link
              href='/auth/signup'
              className='px-6 py-2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-medium rounded-xl transition-all duration-200'
            >
              Get Started
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <main className='max-w-7xl mx-auto px-6 py-20'>
        <div className='text-center max-w-4xl mx-auto'>
          <h1 className='text-6xl font-bold text-white mb-6 leading-tight'>
            Build Beautiful Websites{' '}
            <span className='bg-gradient-to-r from-purple-500 to-blue-500 bg-clip-text text-transparent'>
              Without Code
            </span>
          </h1>
          <p className='text-xl text-slate-400 mb-10 max-w-2xl mx-auto'>
            Choose from beautiful templates and customize your site with our intuitive drag-and-drop editor. No technical skills required.
          </p>
          <div className='flex gap-4 justify-center'>
            <Link
              href='/auth/signup'
              className='px-8 py-4 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 text-white font-semibold rounded-xl transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] shadow-lg shadow-purple-500/25'
            >
              Start Building Free
            </Link>
            <Link
              href='/templates'
              className='px-8 py-4 bg-slate-800 hover:bg-slate-700 text-white font-semibold rounded-xl transition-all duration-200 border border-slate-700'
            >
              Browse Templates
            </Link>
          </div>
        </div>

        {/* Features Grid */}
        <div className='grid grid-cols-1 md:grid-cols-3 gap-8 mt-20'>
          <div className='bg-slate-900/50 backdrop-blur-xl rounded-2xl p-8 border border-slate-800'>
            <div className='w-12 h-12 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-xl flex items-center justify-center mb-4'>
              <svg className='w-6 h-6 text-purple-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM4 13a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zM16 13a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z' />
              </svg>
            </div>
            <h3 className='text-xl font-semibold text-white mb-2'>Drag & Drop Editor</h3>
            <p className='text-slate-400'>Intuitive visual editor that makes building pages feel like playing with blocks.</p>
          </div>

          <div className='bg-slate-900/50 backdrop-blur-xl rounded-2xl p-8 border border-slate-800'>
            <div className='w-12 h-12 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-xl flex items-center justify-center mb-4'>
              <svg className='w-6 h-6 text-purple-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z' />
              </svg>
            </div>
            <h3 className='text-xl font-semibold text-white mb-2'>Beautiful Templates</h3>
            <p className='text-slate-400'>Professional templates for portfolios, businesses, landing pages, and more.</p>
          </div>

          <div className='bg-slate-900/50 backdrop-blur-xl rounded-2xl p-8 border border-slate-800'>
            <div className='w-12 h-12 bg-gradient-to-br from-purple-500/20 to-blue-500/20 rounded-xl flex items-center justify-center mb-4'>
              <svg className='w-6 h-6 text-purple-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M13 10V3L4 14h7v7l9-11h-7z' />
              </svg>
            </div>
            <h3 className='text-xl font-semibold text-white mb-2'>Instant Publishing</h3>
            <p className='text-slate-400'>Publish your site instantly or export it as a zip file to host anywhere.</p>
          </div>
        </div>
      </main>
    </div>
  )
}
