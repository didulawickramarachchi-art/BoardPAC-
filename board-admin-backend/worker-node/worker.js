const Queue = require('bull');
const db = require('./db');
const { sendEmail } = require('./emailSender');
const { sendPush } = require('./pushSender');

const redisUrl = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
const notificationQueue = new Queue('notifications', redisUrl);

notificationQueue.process(async (job) => {
  const { notificationId } = job.data;

  // load notification and recipients
  const res = await db.query('SELECT n.id, n.title, n.message, n.related_meeting_id, u.id as user_id, u.board_email FROM notifications n JOIN users u ON u.status = 1');
  // Minimal example: send to all active users
  for (const row of res.rows) {
    try {
      if (row.board_email) {
        await sendEmail(row.board_email, row.title, row.message);
      }
      // For push, you would lookup device tokens tied to the user
      // Here we skip push or implement by querying devices table
    } catch (err) {
      console.error('Failed to deliver to user', row.user_id, err);
    }
  }

  return true;
});

console.log('Worker started');
