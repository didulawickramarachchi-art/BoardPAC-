Backend Meeting Notifications — Design & Examples

Goal
- Send device push + email to all members when a meeting is created.
- Send device push + email reminder 24 hours before each meeting.

Overview
1) On meeting creation (server-side), create notification records and trigger an immediate delivery job to push/email all members.
2) Also create a scheduled reminder record (send_at = meetingDateTime - 24 hours) to be processed by a background worker.
3) Worker processes immediate delivery jobs and scheduled reminder jobs, sending via configured push (FCM/APNs) and email (SMTP or transactional provider).

Database (example SQL)

-- Notifications table (stores history and can be used to drive UI)
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(64) NOT NULL,
  created_by_user_id INTEGER NULL,
  related_meeting_id INTEGER NULL,
  target_user_id INTEGER NULL,
  announcement BOOLEAN NOT NULL DEFAULT FALSE,
  delivered BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Scheduled notifications (one row per delivery; worker picks rows with send_at <= now())
CREATE TABLE scheduled_notifications (
  id BIGSERIAL PRIMARY KEY,
  notification_id BIGINT NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
  send_at TIMESTAMP WITH TIME ZONE NOT NULL,
  delivered BOOLEAN NOT NULL DEFAULT FALSE,
  last_error TEXT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Optionally: per-user delivery attempts / audit table
CREATE TABLE notification_delivery_log (
  id BIGSERIAL PRIMARY KEY,
  scheduled_notification_id BIGINT REFERENCES scheduled_notifications(id),
  user_id INTEGER NOT NULL,
  channel VARCHAR(16) NOT NULL, -- 'email' or 'push'
  status VARCHAR(16) NOT NULL,
  error TEXT NULL,
  sent_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

API contract
- Meeting creation endpoint (existing): POST /meetings
  - Server returns created meeting with `id` and `meetingDateTime`.
  - Server should call notification creation internally (or frontend can POST a separate /notifications/announcement but best to centralize).

Server-side meeting creation behavior (pseudocode)
1. Create meeting row, commit transaction.
2. Create notifications row with `title`, `message`, `type='MEETING_CREATED'`, `related_meeting_id` set.
3. For immediate broadcast: create a scheduled_notifications row with `send_at = now()` referencing notification.
4. For 24-hour reminder: if meetingDateTime - 24h > now(), create scheduled_notifications with send_at = meetingDateTime - 24h.
5. Worker will process scheduled_notifications and deliver to all target users (all members) by creating per-user delivery logs and invoking email/push providers.

Worker design
- Use a reliable job queue / scheduler (recommended): Redis + Bull (Node.js), Sidekiq (Ruby), RQ/Celery (Python), Hangfire/Quartz (C#), or RQ.
- Alternatively run a cron job that selects due scheduled_notifications rows and processes them atomically.

Node.js (Express + Bull) example (abridged)

1) queue setup

const Bull = require('bull');
const redisOpts = { host: process.env.REDIS_HOST };
const notificationQueue = new Bull('notifications', { redis: redisOpts });

2) Enqueue on meeting creation

// after creating notification record (notificationId)
await notificationQueue.add({ notificationId }, { delay: 0 });
// schedule 24h reminder
const reminderDate = new Date(meetingDateTime);
reminderDate.setHours(reminderDate.getHours() - 24);
if (reminderDate > new Date()) {
  await notificationQueue.add({ notificationId, reminder: true }, { delay: reminderDate - new Date() });
}

3) Worker

notificationQueue.process(async (job) => {
  const { notificationId, reminder } = job.data;
  // load notification and list of users
  const notification = await db('notifications').where({ id: notificationId }).first();
  const users = await db('users').select('id','email','fcm_token').where('active', true);

  for (const user of users) {
    try {
      // send email
      await sendEmail(user.email, notification.title, notification.message);
      // send push
      if (user.fcm_token) await sendPush(user.fcm_token, notification.title, notification.message);
      // record delivery
      await db('notification_delivery_log').insert({...});
    } catch (err) {
      // log error, optionally retry per-user
    }
  }

  await db('scheduled_notifications').where({ id: job.data.scheduledId }).update({ delivered: true });
});

Email & push integration
- Email: use SMTP via nodemailer or a transactional provider (SendGrid, Mailgun). Use templates; include meeting link and meeting id.
- Push: FCM for Android & Web, APNs for iOS. Send both a data payload and a notification payload. Prefer server-managed tokens and topic broadcasts.

Security & scale notes
- For "all members", prefer sending a single topic broadcast (FCM topics) if your backend holds groups; push provider topic reduces API calls.
- For email, use batching and proper rate limits; use provider's bulk send features.
- Protect endpoints; only authorized services should schedule deliveries.

Testing guidance
- Unit test worker functions with a mock email/push provider.
- Integration: create a meeting with a near-future `meetingDateTime` and verify two deliveries: immediate, and scheduled 24-hour reminder (simulate time or set meetingDateTime to now + 25 hours and wait).

Example curl to test announcement endpoint (if using existing announcement API)

curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"title":"New meeting","message":"Details...","type":"MEETING_CREATED","announcement":true}' \
  https://your-api.example.com/notifications/announcement

Next steps I can take for you
- Draft a concrete server patch in your backend language (Node/Express, Spring Boot, Django, etc.) — tell me which stack to target and I will produce code and migration files.
- Add a simple local-device reminder implementation to the Flutter app (uses flutter_local_notifications) as a fallback.

