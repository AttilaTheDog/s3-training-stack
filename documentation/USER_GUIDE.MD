# End-User Guide: Connecting to Your MinIO Storage

Your MinIO instance gives you an **S3‑compatible storage service** with a web interface. Follow these steps:

---

## 1) Access Your MinIO Instance

1. Open your web browser.
2. Go to your unique MinIO console URL:

   ```
   https://console-<trainingID>.s3.mindrefined.de
   ```

   - Replace `<trainingID>` with your assigned number.  
     Example for **Training01**:
     ```
     https://console-training01.s3.mindrefined.de
     ```

---

## 2) Log In

1. You will receive two credentials:
   - **Username (Access Key)**:  
     ```
     MINIO_ROOT_USER
     ```
   - **Password (Secret Key)**:  
     ```
     MINIO_ROOT_PASSWORD
     ```
2. Enter them on the login screen and press **Login**.

> 💡 If you forget your credentials, ask your admin/trainer to re-issue them.

---

## 3) Create a Bucket

A **bucket** is like a folder where you can upload and organize your files.

1. After logging in, click **Buckets** in the left-hand menu.
2. Click **+ Create Bucket**.
3. Enter a bucket name (e.g. `backups` or `project-data`).  
   - Bucket names must be unique **within your instance** and all lowercase.
4. Leave the default settings and click **Create Bucket**.

You should now see your bucket in the list.

---

## 4) Upload Files or Use S3 Tools

- To upload via the web console:
  1. Click your bucket name.
  2. Click **Upload**, drag-and-drop files, and click **Upload**.

- To connect using S3-compatible tools (AWS CLI, `mc`, or backup software):
  - **S3 Endpoint:**  
    ```
    https://<trainingID>.s3.mindrefined.de
    ```
  - **Access Key:** `MINIO_ROOT_USER`
  - **Secret Key:** `MINIO_ROOT_PASSWORD`

> Example: for training01  
> Endpoint:  
> ```
> https://training01.s3.mindrefined.de
> ```

---

## 5) Optional: Test With MinIO Client (mc)

1. [Install `mc`](https://min.io/docs/minio/linux/reference/minio-mc.html) (Linux, Mac, or Windows).
2. Add your MinIO instance:
   ```bash
   mc alias set myminio https://<trainingID>.s3.mindrefined.de MINIO_ROOT_USER MINIO_ROOT_PASSWORD
   ```
3. List your buckets:
   ```bash
   mc ls myminio
   ```
4. Create another bucket:
   ```bash
   mc mb myminio/mybucket
   ```

---

## 6) Next Steps

- Use your bucket for storing data or configuring as a target in compatible software.
- Do **not share** your credentials. Buckets and data are private to your instance.
