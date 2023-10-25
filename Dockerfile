ARG X_TAG
# Install dependencies only when needed
FROM node:18-alpine AS deps
 
WORKDIR /opt/app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --ignore-scripts
 
# Rebuild the source code only when needed
# This is where because may be the case that you would try
# to build the app based on some `X_TAG` in my case (Git commit hash)
# but the code hasn't changed.
FROM node:18-alpine AS builder

ENV NEXT_TELEMETRY_DISABLED 1

ENV NODE_ENV=production
WORKDIR /opt/app
COPY . .
COPY --from=deps /opt/app/node_modules ./node_modules
RUN yarn build
# Workaround part 1: Create empty files and folders to replicate the structure of the pages in the app

# Production image, copy all the files and run next
FROM node:16-alpine AS runner

WORKDIR /opt/app
ENV NODE_ENV=production

COPY --from=builder /opt/app/next.config.js ./
# Workaround part 2: Copy the empty files and folders to the run environment so next-translate can figure out how the pages are laid out.
COPY --from=builder /opt/app/public ./public
COPY --from=builder /opt/app/.next ./.next
COPY --from=builder /opt/app/node_modules ./node_modules
COPY --from=builder /opt/app/package.json ./package.json
EXPOSE 3000
CMD [ "yarn", "start" ]