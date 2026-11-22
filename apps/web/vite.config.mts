import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), 'VITE_');
  return {root:'apps/web',plugins:[react()],define:{__API_BASE_URL__:JSON.stringify(env.VITE_API_BASE_URL || '')},server:{port:5173,proxy:{'/api':'http://127.0.0.1:3000'}},build:{outDir:'../../dist/web',emptyOutDir:true}};
});
