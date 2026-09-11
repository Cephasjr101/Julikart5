# Build stage — devDependencies (vite, esbuild) are required to build.
# NODE_ENV is forced to development so `npm ci` never skips devDependencies,
# even if the deploy environment injects NODE_ENV=production.
FROM node:20-slim AS build
WORKDIR /app
ENV NODE_ENV=development
COPY package.json package-lock.json ./
RUN npm ci --include=dev
COPY . .
RUN npm run build

# Runtime stage — the server bundle (dist/boot.js) has all npm deps inlined;
# it only needs Node built-ins plus the static frontend in dist/public.
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
# runtime.env holds the platform credentials (same content as .env, which is
# excluded from Docker build contexts as a hidden file — copied in as .env).
COPY package.json ./
COPY runtime.env ./.env
COPY --from=build /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/boot.js"]
