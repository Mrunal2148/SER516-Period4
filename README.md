# SER516 Period 4 Fallback

## How to Run

1. Clone the repository.
2. Run `docker-compose pull` to pull the images for the services.
3. Run `docker-compose up` to start the services.
4. The backend will be available at `http://localhost:8080`.
5. The frontend will be available at `http://localhost:8043`.

## How to Test the Backend

1. Make sure the backend is running.

2. Add a repo to the database by sending a POST request to `http://localhost:8080/add_repo`

```bash
curl --location 'http://localhost:8080/add_repo' \
--header 'Content-Type: application/json' \
--data '{
    "repo_url": "https://github.com/kgary/ser421public"
}'
```

3. Get a specific metric by sending a GET request to `http://localhost:8080/get_metric`

```bash
curl --location 'http://localhost:8080/get_metrics?repo_url=https%3A%2F%2Fgithub.com%2Fkgary%2Fser421public&metrics=hal%2Ccyclo'
```

## Setting the Ports

The ports for the backend and frontend are set in the `.env` file. You can change the ports by modifying the `GATEWAY_PORT` and `CLIENT_PORT` variables in the `.env` file.

