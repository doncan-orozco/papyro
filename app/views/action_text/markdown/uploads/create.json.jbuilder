json.message "File uploaded successfully"
json.fileName @upload.filename.to_s
json.mimetype @upload.content_type
json.fileUrl @upload.slug_url(**public_upload_host_options)
