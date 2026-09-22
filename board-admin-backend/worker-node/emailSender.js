const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT || 587),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

function escapeHtml(value) {
  return String(value || '').replace(/[&<>"']/g, (char) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[char]);
}

function emailHtml(subject, text) {
  const icon = escapeHtml(process.env.APP_ICON_URL || 'https://boardpac.srilankaports.com/assets/images/logo.png');
  const content = escapeHtml(text).replace(/\r\n?/g, '\n').replace(/\n\n+/g, '</p><p style="margin:0 0 16px">').replace(/\n/g, '<br>');
  return `<!doctype html><html><body style="margin:0;background:#f3f6fc;font-family:Arial,sans-serif;color:#172033"><table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="padding:28px 12px"><tr><td align="center"><table role="presentation" width="600" style="max-width:600px;width:100%;background:#fff;border-radius:18px;overflow:hidden;border:1px solid #e1e6f0"><tr><td style="background:#12275b;padding:24px 30px"><table role="presentation"><tr><td><img src="${icon}" alt="BoardPAC" width="58" height="58" style="display:block;border-radius:14px;background:#fff;object-fit:contain"></td><td style="padding-left:16px;color:#fff"><div style="font-size:21px;font-weight:700">BoardPAC</div><div style="color:#ffb52e;font-size:12px;margin-top:4px">SRI LANKA PORTS AUTHORITY</div></td></tr></table></td></tr><tr><td style="padding:32px 30px"><h1 style="font-size:22px;color:#061b4e;margin:0 0 20px">${escapeHtml(subject)}</h1><p style="font-size:15px;line-height:1.65;margin:0 0 16px">${content}</p></td></tr><tr><td style="padding:18px 30px;background:#f8f9fc;border-top:1px solid #e1e6f0;color:#7d8cb2;font-size:12px">This is an automated BoardPAC notification. Please do not reply.</td></tr></table></td></tr></table></body></html>`;
}

async function sendEmail(to, subject, text) {
  await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to,
    subject,
    text,
    html: emailHtml(subject, text),
  });
}

module.exports = { sendEmail };
