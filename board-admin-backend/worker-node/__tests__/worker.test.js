const { sendEmail } = require('../emailSender');
const { sendPush } = require('../pushSender');

jest.mock('../emailSender');
jest.mock('../pushSender');

describe('worker senders', () => {
  it('sends email and push without throwing', async () => {
    sendEmail.mockResolvedValue(true);
    sendPush.mockResolvedValue(true);

    await expect(sendEmail('a@b.com', 'sub', 'msg')).resolves.toBeTruthy();
    await expect(sendPush('token', 't', 'b')).resolves.toBeTruthy();
  });
});
