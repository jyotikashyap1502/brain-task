# Step 1: Use a lightweight Nginx image
FROM nginx:alpine

# Step 2: Copy build output to Nginx HTML folder
COPY dist/ /usr/share/nginx/html

# Step 3: Expose port 80 for the web server
EXPOSE 80

# Step 4: Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
