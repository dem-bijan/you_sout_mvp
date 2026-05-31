const fastify = require('fastify')({ logger: true })
const proxy = require('fastify-http-proxy')
const fs = require('fs')
const path = require('path')
const jwt = require('jsonwebtoken')

// Load public key for JWT verification (mounted secret)
const publicKeyPath = path.join(__dirname, 'keys', 'public.pem')
let publicKey = ''
try {
  publicKey = fs.readFileSync(publicKeyPath, 'utf8')
} catch (err) {
  fastify.log.warn('Public key not found, JWT verification will be skipped')
}

// Register JWT verification preHandler
fastify.addHook('preHandler', async (request, reply) => {
  const authHeader = request.headers['authorization']
  if (!authHeader) {
    // allow unauthenticated for public routes (e.g., health check)
    return
  }
  const token = authHeader.split(' ')[1]
  try {
    const decoded = jwt.verify(token, publicKey, { algorithms: ['RS256'] })
    request.user = decoded
  } catch (err) {
    reply.code(401).send({ error: 'Invalid token' })
  }
})

// Proxy routes to downstream services
fastify.register(proxy, {
  upstream: 'http://user-service:8001',
  prefix: '/users', // /users/* -> user service
  http2: false,
})
fastify.register(proxy, {
  upstream: 'http://video-service:8002',
  prefix: '/videos',
  http2: false,
})
fastify.register(proxy, {
  upstream: 'http://interaction-service:8003',
  prefix: '/interactions',
  http2: false,
})

// Health check endpoint
fastify.get('/health', async (request, reply) => {
  return { status: 'ok' }
})

const start = async () => {
  try {
    await fastify.listen({ port: 8080, host: '0.0.0.0' })
    fastify.log.info(`Gateway listening on ${fastify.server.address().port}`)
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}
start()
