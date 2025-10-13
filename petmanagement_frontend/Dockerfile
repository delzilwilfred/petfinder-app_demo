# Multi-stage build for Angular app
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies for faster builds
RUN apk add --no-cache python3 make g++

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies with optimizations
RUN npm ci --prefer-offline --no-audit --progress=false

# Copy source code
COPY . .

# Build with optimizations
RUN sed -i '/"fileReplacements":/,/]/d' angular.json && \
    npm run build -- --configuration=development --optimization=false --source-map=false --build-optimizer=false

# Production stage
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install --only=production --no-audit --progress=false && npm cache clean --force

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist

# Copy server configuration
COPY server.ts ./

# Expose port
EXPOSE 4000

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Change ownership of app directory
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Start the SSR server
CMD ["npm", "run", "serve:ssr:petmanagement"]