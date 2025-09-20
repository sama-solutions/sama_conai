# 🔧 GitHub Upload Troubleshooting Guide

## ❌ **Current Error**
```
remote: {"auth_status":"access_denied_to_user","body":"Permission to sama-solutions/conai.git denied to sama-solutions."}
fatal: impossible d'accéder à 'https://github.com/sama-solutions/conai.git/' : The requested URL returned error: 403
```

## 🔍 **Possible Causes & Solutions**

### **1. Repository Doesn't Exist (Most Likely)**

The repository `sama-solutions/conai` might not exist on GitHub yet.

**Solution: Create the repository first**

#### **Option A: Create via GitHub Web Interface**
1. Go to https://github.com/sama-solutions
2. Click "New repository" (green button)
3. Repository name: `conai`
4. Description: "SAMA CONAI - Module Odoo pour la transparence au Sénégal"
5. Set to **Public**
6. **DO NOT** initialize with README, .gitignore, or license (we already have these)
7. Click "Create repository"

#### **Option B: Create via GitHub CLI** (if installed)
```bash
gh repo create sama-solutions/conai --public --description "SAMA CONAI - Module Odoo pour la transparence au Sénégal"
```

### **2. Authentication Token Issue**

If the repository exists but you still get 403, the issue is authentication.

**Solution: Use Personal Access Token**

1. **Create Personal Access Token:**
   - Go to https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Name: "SAMA CONAI Upload"
   - Expiration: 30 days (or as needed)
   - Scopes: Check `repo` (full repository access)
   - Click "Generate token"
   - **Copy the token immediately** (you won't see it again)

2. **Push with token:**
   ```bash
   git push -u origin main
   # Username: sama-solutions
   # Password: [paste your personal access token here]
   ```

### **3. Organization Permissions**

If `sama-solutions` is an organization, you might need proper permissions.

**Solution: Check organization settings**
1. Go to https://github.com/sama-solutions
2. Check if you have admin/write access
3. If not, ask an organization admin to:
   - Add you as a member with write permissions
   - Or create the repository and add you as a collaborator

### **4. Alternative: Use Your Personal Account**

If you can't access the `sama-solutions` organization, create the repository under your personal account first.

**Solution: Change remote to your personal account**
```bash
# Change remote to your personal account
git remote set-url origin https://github.com/YOUR_USERNAME/conai.git

# Push to your personal account
git push -u origin main

# Later, you can transfer the repository to sama-solutions organization
```

## 🚀 **Recommended Steps**

### **Step 1: Create Repository on GitHub**
1. Go to https://github.com/sama-solutions
2. Click "New repository"
3. Name: `conai`
4. Description: "SAMA CONAI - Module Odoo pour la transparence au Sénégal"
5. Public repository
6. **Don't initialize** with any files
7. Create repository

### **Step 2: Get Personal Access Token**
1. Go to https://github.com/settings/tokens
2. Generate new token with `repo` scope
3. Copy the token

### **Step 3: Push with Token**
```bash
cd /home/grand-as/psagsn/custom_addons/sama_conai
git push -u origin main
# Username: sama-solutions
# Password: [your_personal_access_token]
```

### **Step 4: Create Release Tag**
```bash
git tag -a v18.0.1.0.0 -m "SAMA CONAI v18.0.1.0.0 - Initial Release"
git push origin --tags
```

## 🔄 **Alternative: SSH Authentication**

If token authentication continues to fail, try SSH:

### **Setup SSH Key**
```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy public key
cat ~/.ssh/id_ed25519.pub
# Copy the output and add it to GitHub → Settings → SSH and GPG keys
```

### **Change Remote to SSH**
```bash
git remote set-url origin git@github.com:sama-solutions/conai.git
git push -u origin main
```

## 🆘 **If All Else Fails**

### **Option 1: Use Your Personal Account Temporarily**
```bash
# Create repository under your personal account
git remote set-url origin https://github.com/YOUR_USERNAME/sama-conai.git
git push -u origin main

# Later transfer to sama-solutions organization via GitHub web interface
```

### **Option 2: Create Repository Manually**
1. Create the repository on GitHub manually
2. Upload files via GitHub web interface (drag and drop)
3. This is slower but guaranteed to work

## 📋 **Verification Steps**

After successful upload, verify:
1. Repository visible at https://github.com/sama-solutions/conai
2. All files uploaded (should see 990 files)
3. README.md displays correctly
4. Installation instructions work

## 🎯 **Expected Success Output**

When the push succeeds, you should see:
```
Enumerating objects: 1234, done.
Counting objects: 100% (1234/1234), done.
Delta compression using up to 8 threads
Compressing objects: 100% (567/567), done.
Writing objects: 100% (1234/1234), 45.67 MiB | 2.34 MiB/s, done.
Total 1234 (delta 890), reused 1234 (delta 890)
remote: Resolving deltas: 100% (890/890), done.
To https://github.com/sama-solutions/conai.git
 * [new branch]      main -> main
Branch 'main' set up to track remote branch 'main' from 'origin'.
```

## 📞 **Need Help?**

If you continue to have issues:
1. Check if you have access to the `sama-solutions` organization
2. Verify the repository name is correct
3. Try creating the repository manually on GitHub first
4. Contact GitHub support if authentication issues persist

---

**The repository is ready to upload - we just need to resolve the GitHub access issue!** 🚀