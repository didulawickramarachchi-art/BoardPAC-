const Queue = require('bull');
const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
const queue = new Queue('notifications', redisUrl);

async function enqueueExample() {
  await queue.add({ notificationId: 1 });
  console.log('Enqueued example notification');
  process.exit(0);
}

enqueueExample();
