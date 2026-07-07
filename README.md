# Capstone OnlineShop Deployment Walkthrough

This project is a containerized React e-commerce application served with Nginx and deployed through a Jenkins CI/CD pipeline. It also includes a monitoring stack with Prometheus, Blackbox Exporter, and Grafana running on a shared Docker network.

The monitoring setup was configured and tested in a local Docker environment on `localhost`. This approach was chosen to avoid additional AWS infrastructure costs while still demonstrating application health checks, metrics collection, and dashboard visualization.

The walkthrough below is designed to be read alongside the screenshots in the `screenshots/` folder. If your screenshot filenames are different, update the image paths in this README.

## Project Overview

- Application: React single-page e-commerce app
- Web server: Nginx
- Container image: `joelrobinson791/capstone-app`
- CI/CD: Jenkins pipeline
- Monitoring: Prometheus, Blackbox Exporter, and Grafana
- App port: `80`
- Grafana port: `3000`
- Prometheus port: `9090`
- Blackbox Exporter port: `9115`

## Architecture

The application is built into static frontend files under `build/`. The `Dockerfile` copies those files into an Nginx container and serves them from `/web/data/`.

```text
React build files
      |
      v
Docker image with Nginx
      |
      v
Docker Hub
      |
      v
Production server
      |
      v
Prometheus + Blackbox Exporter + Grafana monitoring
```

## Screenshot Walkthrough

### 1. Home Page

![Home page](screenshots/01-home-page.png)

The home page is the main shopping view of the OnlineShop application. Users can browse products, open the cart, and navigate to login or signup from the top navigation bar.

### 2. Signup Page

![Signup page](screenshots/02-signup-page.png)

New users can create an account from the signup page by entering a user name, email address, and password. After signup, the app redirects users toward the login flow.

### 3. Login Page

![Login page](screenshots/03-login-page.png)

Existing users log in with their email address and password. After a successful login, the application stores the user token locally and displays authenticated navigation options such as orders and logout.

### 4. Cart Page

![Cart page](screenshots/04-cart-page.png)

The cart page shows the selected products, quantities, and totals. Users can continue shopping or proceed through the purchase flow.

### 5. Orders Page

![Orders page](screenshots/05-orders-page.png)

After checkout, users can view their order summary. The orders table includes product details, quantity, total amount, payment status, delivery status, and payment intent information.

### 6. Docker Image Build

![Docker build](screenshots/06-docker-build.png)

The app is packaged using the `Dockerfile`:

```dockerfile
FROM nginx:stable-alpine
COPY build/ /web/data/
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

Nginx serves the React app and falls back to `index.html` for client-side routing.

### 7. Jenkins Pipeline

![Jenkins pipeline](screenshots/07-jenkins-pipeline.png)

The `Jenkinsfile` automates the build and deployment workflow:

1. Detects the branch that triggered the pipeline.
2. Captures the short Git commit hash.
3. Builds a Docker image.
4. Logs in to Docker Hub using Jenkins credentials.
5. Pushes both a unique image tag and a readable image tag.
6. Connects to the deployment server over SSH.
7. Pulls and runs the new container on port `80`.

The pipeline uses separate image names for production and development:

```text
Production image: joelrobinson791/capstone-app
Development image: joelrobinson791/capstone-app-dev
```

### 8. Running Containers

![Running containers](screenshots/08-running-containers.png)

The project can run the app and monitoring services together with Docker Compose:

```bash
docker network create monitoring
docker compose up -d
```

The Compose file starts:

- `web`: the OnlineShop app on port `80`
- `grafana`: dashboards on port `3000`
- `prometheus`: metrics on port `9090`
- `blackbox-exporter`: HTTP probing on port `9115`

The services use an existing external Docker network:

```yaml
networks:
  monitoring:
    external: true
```

### 9. Prometheus Targets

![Prometheus targets](screenshots/09-prometheus-targets.png)

Prometheus is configured in `prom.yml`. It scrapes Prometheus itself and uses Blackbox Exporter to check the application health endpoint through HTTP probing.

```yaml
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets:
          - "prometheus:9090"

  - job_name: "app-health"
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - "http://web:80"
```

### 10. Grafana Dashboard

![Grafana dashboard](screenshots/10-grafana-dashboard.png)

Grafana connects to Prometheus and visualizes the app health metrics. A typical dashboard can show whether the web app is reachable, probe duration, HTTP status, and service availability over time.

## Local Run

Make sure Docker is installed and the `monitoring` network exists:

```bash
docker network create monitoring
```

Start the full stack:

```bash
docker compose up -d
```

Open the services:

```text
Application: http://localhost
Grafana:     http://localhost:3000
Prometheus:  http://localhost:9090
Blackbox:    http://localhost:9115
```

To stop the stack:

```bash
docker compose down
```

## Manual Image Build

You can build the application image manually with:

```bash
docker build -t joelrobinson791/capstone-app:v1 .
```

Or use the helper script:

```bash
./build-image.sh
```

## Manual Deployment

The deployment helper pulls an image and runs it on port `80`:

```bash
./deploy-instance.sh
```

Default image:

```text
joelrobinson791/capstone-app:v1
```

## CI/CD Flow

The Jenkins pipeline expects these credentials to exist in Jenkins:

```text
docker-hub-credentials
ssh-credentials
```

On the `main` branch, Jenkins builds and pushes the production image. On other branches, it builds and pushes the development image. Each build gets:

- A readable tag, such as `latest`
- A unique tag that includes the short commit hash

After pushing the image, Jenkins deploys it to the configured server by pulling the new image and restarting the running container.

## Monitoring Flow

For cost control, the monitoring stack was run locally with Docker instead of being hosted on AWS. This kept the project affordable while still showing how Prometheus, Blackbox Exporter, and Grafana can monitor the deployed web application.

The monitoring setup checks the web application through Blackbox Exporter:

```text
Prometheus -> Blackbox Exporter -> OnlineShop web container
```

This makes it possible to monitor the app from the outside, similar to how a user or browser would reach it.

## Useful Commands

```bash
docker compose ps
docker compose logs web
docker compose logs prometheus
docker compose logs grafana
docker compose logs blackbox-exporter
```

Check that the app is reachable:

```bash
curl http://localhost
```

Check Prometheus targets:

```text
http://localhost:9090/targets
```

## Repository Files

```text
Dockerfile             Builds the Nginx image for the React app
nginx.conf             Serves the React build and supports client-side routes
docker-compose.yaml    Runs the app and monitoring stack
prom.yml               Prometheus scrape configuration
Jenkinsfile            CI/CD pipeline for build, push, and deployment
build-image.sh         Manual Docker image build helper
deploy-instance.sh     Manual deployment helper
build/                 Production React build output
screenshots/           Walkthrough screenshots for this README
```
