import { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="min-h-screen bg-background p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-4">shadcn/ui Catalog</h1>
        <p className="text-muted-foreground mb-8">
          React reference implementation for Papyro Phlex components
        </p>
        
        <div className="border border-border rounded-lg p-6">
          <h2 className="text-2xl font-semibold mb-4">Setup Complete</h2>
          <p className="mb-4">
            Next steps:
          </p>
          <ol className="list-decimal list-inside space-y-2 text-sm">
            <li>Install dependencies: <code className="bg-muted px-2 py-1 rounded">npm install</code></li>
            <li>Initialize shadcn/ui: <code className="bg-muted px-2 py-1 rounded">npx shadcn@latest init</code></li>
            <li>Add components: <code className="bg-muted px-2 py-1 rounded">npx shadcn@latest add button</code></li>
          </ol>
        </div>

        <div className="mt-6">
          <button
            onClick={() => setCount((count) => count + 1)}
            className="bg-primary text-primary-foreground px-4 py-2 rounded-md hover:bg-primary/90 transition-colors"
          >
            Count is {count}
          </button>
        </div>
      </div>
    </div>
  )
}

export default App
