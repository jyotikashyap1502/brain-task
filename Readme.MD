# Brain Task Project

## Running the Project

Follow these steps to run the project locally:

1. Navigate to the project directory:

```bash
cd path/to/brain-task 
```

2. Install the `serve` package globally:

```bash
sudo npm install -g serve
```

3. Verify the installation:

```bash
serve -v
```

4. Serve the production build:

```bash
serve -s dist
```

The project should now be running locally, and you can access it in your browser.

## after creating Docker File

# Build Docker image
docker build -t brain-task-app:latest .

# Run the container
docker run -d -p 3000:80 brain-task-app:latest

# go to the browser and test it.
test the project on localhost:30000



