# 🔧 Fix Cloud Functions Permissions

**Issue**: Permission denied when deploying Cloud Functions  
**Error**: `artifactregistry.repositories.list` permission missing

---

## ⚡ Quick Fix (2 minutes)

### Option 1: Automatic Fix (Easiest)

Run this command to grant the required permission:

```bash
gcloud projects add-iam-policy-binding trippo-42089 \
  --member="serviceAccount:trippo-42089@appspot.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

Then deploy again:

```bash
firebase deploy --only functions
```

### Option 2: Manual Fix (via Console)

1. **Go to**: [Google Cloud Console - IAM](https://console.cloud.google.com/iam-admin/iam?project=trippo-42089)

2. **Find the service account**:
   - Look for: `trippo-42089@appspot.gserviceaccount.com`
   - Or: `App Engine default service account`

3. **Edit permissions**:
   - Click the pencil (edit) icon next to the account
   - Click "ADD ANOTHER ROLE"
   - Search for: `Artifact Registry Reader`
   - Select it
   - Click "SAVE"

4. **Deploy again**:
   ```bash
   cd trippo_user
   firebase deploy --only functions
   ```

---

## 🎯 What This Does

This grants the Cloud Functions service account permission to:
- ✅ Read from Artifact Registry
- ✅ Deploy 1st Gen Cloud Functions
- ✅ Store and retrieve function artifacts

**Security**: This is a read-only permission and is safe to grant.

---

## 🧪 Verify It Worked

After granting the permission:

```bash
# Deploy functions
firebase deploy --only functions

# Expected output:
# ✔ functions: all functions deployed successfully!
# 
# Functions:
#   createStripeCustomer(us-central1): https://us-central1-trippo-42089.cloudfunctions.net/createStripeCustomer
#   attachPaymentMethod(us-central1): https://...
#   detachPaymentMethod(us-central1): https://...
```

---

## 💡 Why This Happened

Firebase recently changed how Cloud Functions deploy artifacts. They now use Artifact Registry instead of Container Registry, which requires this additional permission.

This is a one-time setup for your project.

---

## ✅ After Fixing

Once deployed successfully:

1. Test in app:
   - Login as passenger
   - Profile → Payment Methods
   - Click "Add Payment Method"
   - ✅ Should work automatically!

2. Verify in Firebase Console:
   - Go to: Functions section
   - Should see 3 active functions

---

**Need Help?**

If the gcloud command doesn't work:
1. Make sure you're logged in: `gcloud auth login`
2. Set the project: `gcloud config set project trippo-42089`
3. Try the command again

Or just use the manual console method above (easier).

