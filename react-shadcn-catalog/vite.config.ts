/// <reference types="node" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig(({ command }) => ({
  plugins: [react(), tailwindcss()],
  resolve: { alias: { '@': path.resolve(__dirname, './src'), '@scenarios': path.resolve(__dirname, '../docs/shadcn-port/scenarios'), '@host-theme': path.resolve(__dirname, '../app/assets/tailwind/theme') } },
  server: { fs: { allow: ['..'] } },
  base: command === 'build' ? '/react-catalog/' : '/',
  build: { outDir: '../public/react-catalog', emptyOutDir: true },
}))
