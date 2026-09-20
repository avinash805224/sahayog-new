import { defineConfig } from 'vite'
import { viteStaticCopy } from 'vite-plugin-static-copy'

export default defineConfig({
  plugins: [
    viteStaticCopy({
      targets: [
        { src: 'landing.html', dest: '' },
        { src: 'admin.html', dest: '' },
        { src: 'app.html', dest: '' }
      ]
    })
  ]
})
