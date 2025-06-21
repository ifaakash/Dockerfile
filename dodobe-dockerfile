# Base image
FROM node@sha256:f9ab18e354e6855ae56ef2b290dd225c1e51a564f87584b9bd21dd651838830e AS builder
WORKDIR /app

# install the required build packages that are not in slim image and pnpm
RUN apt-get update && apt-get install -y curl git build-essential python3
RUN npm install -g pnpm@8.15.4

# Copy only whats needed for dependencies & Install
COPY package*.json pnpm-lock.yaml ./
RUN pnpm clean
RUN pnpm i --frozen-lockfile

# copy the rest application code
COPY . .

RUN pnpm build

# Runner state to only copy the required code
FROM node@sha256:f9ab18e354e6855ae56ef2b290dd225c1e51a564f87584b9bd21dd651838830e AS runner

WORKDIR /app

COPY --from=builder ./app/dist ./dist
COPY --from=builder ./app/package*.json ./
COPY --from=builder /app/pnpm-lock.yaml ./
COPY --from=builder /app/src/docs ./src/docs
COPY --from=builder /app/src/docs ./dist/docs

# Install only production dependencies
RUN npm install -g pnpm && pnpm install --prod --frozen-lockfile

# Expose the port your app listens on
# Backedn code has port 3002
EXPOSE 3001

# Run the application in DEV mode
CMD ["node", "dist/app.js"]
