import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth({
  keyFile: new URL('./sa_key.json', import.meta.url).pathname,
  scopes: [
    'https://www.googleapis.com/auth/drive',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/calendar',
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/documents',
    'https://www.googleapis.com/auth/admin.reports.audit.readonly',
  ],
});

const client = await auth.getClient();
const token = await client.getAccessToken();
process.stdout.write(token.token);
