# Railway Setup Instructions for ParkEase

## Current Status
Based on your screenshots:
- ✅ **glistening-rebirth** project exists with ParkEase service
- ✅ **PostgreSQL** database is connected
- ❌ **Public URL** not generated for ParkEase service

## How to Generate Public URL

### Step 1: Generate Domain in Railway
1. Go to Railway Dashboard
2. Click on **glistening-rebirth** project
3. Click on **parkease** service (with GitHub icon)
4. Go to **Settings** tab
5. Scroll to **Networking** or **Public Networking** section
6. Click **"Generate Domain"** button
7. Copy the generated URL (e.g., `parkease-production-xxx.up.railway.app`)

### Step 2: Update Admin Panel Configuration
Once you have the URL, update `C:\Users\Asus\Quickbill\js\config.js`:

```javascript
window.PARKEASE_CONFIG = {
    api: {
        baseUrl: 'https://YOUR-GENERATED-URL.up.railway.app', // <-- Put Railway URL here
        // ... rest of config
    }
}
```

### Step 3: Set Environment Variables in Railway
In the parkease service settings, add these variables:

```env
NODE_ENV=production
JWT_SECRET=your-secret-key-change-this
JWT_REFRESH_SECRET=another-secret-key-change-this
ADMIN_PANEL_URL=https://deepanshuvermaa.github.io/quickbill-admin
```

The `DATABASE_URL` should already be set automatically by Railway.

### Step 4: Trigger Redeploy
After setting environment variables:
1. Click **"Deploy"** or **"Redeploy"** button
2. Wait for deployment to complete (usually 2-3 minutes)

### Step 5: Test the Connection
Open browser console and test:

```javascript
fetch('https://YOUR-GENERATED-URL.up.railway.app/health')
  .then(r => r.json())
  .then(console.log)
```

Should return: `{status: 'healthy', timestamp: '...', version: '1.0.0'}`

## Troubleshooting

### If deployment fails:
1. Check **Deploy Logs** in Railway
2. Common issues:
   - Missing environment variables
   - Port binding issues (Railway provides PORT automatically)
   - Build command errors

### If health check fails:
1. Check if the service is running (green checkmark in Railway)
2. Verify the URL is correct
3. Check CORS settings in backend

### If admin panel can't connect:
1. Verify the URL in config.js
2. Check browser console for CORS errors
3. Ensure JWT_SECRET is set in Railway

## Alternative: Use QuickBill's Backend
If you want to combine both services, you could:
1. Copy ParkEase API routes to QuickBill backend
2. Use `quickbill-production.up.railway.app` for both
3. This would simplify deployment but mix concerns

## Current Working Service
Your QuickBill service is working at:
- URL: `quickbill-production.up.railway.app`
- Project: blissful-energy
- Status: ✅ Running

## Next Steps
1. Generate public URL for parkease service
2. Update config.js with the URL
3. Push changes to GitHub
4. Test the connection

---

**Note**: Railway may take 1-2 minutes to provision the domain after clicking "Generate Domain"