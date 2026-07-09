# Capstone OnlineShop DevOps Walkthrough

This project demonstrates a complete DevOps workflow for a React e-commerce application called **OnlineShop**. The app is containerized with Docker, served with Nginx, pushed to Docker Hub, deployed through Jenkins to an AWS EC2 instance, and monitored with a local Docker-based Prometheus, Blackbox Exporter, and Grafana stack.

The monitoring stack was intentionally configured on `localhost` in a local Docker environment because running extra monitoring infrastructure on AWS would increase project costs. This still demonstrates health checks, Prometheus metrics, Blackbox probing, and Grafana visualization without requiring additional cloud resources.

This README was updated after the redo review to include clearer Jenkins successful build console output, successful Docker Hub image pull and deployment output, EC2 deployment proof, and monitoring screenshots for evaluation.

## Project Overview

- Application: React single-page e-commerce app
- Web server: Nginx
- Production image: `joelrobinson791/capstone-app`
- Development image: `joelrobinson791/capstone-app-dev`
- CI/CD: Jenkins multibranch pipeline
- Registry: Docker Hub
- Deployment target: AWS EC2
- Local monitoring: Prometheus, Blackbox Exporter, and Grafana
- App port: `80`
- Grafana port: `3000`
- Prometheus port: `9090`
- Blackbox Exporter port: `9115`

## Redo Evidence Added After Review

The reviewer feedback asked for clearer proof of Jenkins build success, EC2 deployment, and monitoring output. The following evidence was added to make those results easy to verify.

### Jenkins Successful Console Output

The Jenkins multibranch pipeline detected the `dev` branch, built the Docker image, pushed it to Docker Hub, pulled the public development image on the server, recreated the container, and ended with `Finished: SUCCESS`.

![Jenkins dev branch successful console output](<screenshots/Screenshot 2026-07-09 130103.png>)

The `main` branch run detected `origin/main`, logged in to Docker Hub on the EC2 instance, pulled the private production image, recreated the running container, and also completed successfully.

![Jenkins main branch successful console output](<screenshots/Screenshot 2026-07-09 130432.png>)

### EC2 Deployment Proof

The AWS EC2 instance used for deployment is running and has the public IP address `34.192.210.74`.

![AWS EC2 app server running](<screenshots/Screenshot 2026-07-09 130714.png>)

The OnlineShop application is reachable from the EC2 public IP address after Jenkins deployment.

![OnlineShop deployed from EC2 public IP](<screenshots/Screenshot 2026-07-09 130735.png>)

### Monitoring Proof

The monitoring stack uses Prometheus, Blackbox Exporter, and Grafana in the local Docker environment. Screenshots for the running containers, Blackbox probe result, Prometheus configuration, Grafana dashboard, and failure detection are included in the monitoring section below.

## Architecture

```text
React build output
      |
      v
Nginx Docker image
      |
      v
Docker Hub
      |
      v
Jenkins pipeline
      |
      v
AWS EC2 deployment

Local monitoring environment:

Docker Compose
      |
      +-- OnlineShop web container
      +-- Prometheus
      +-- Blackbox Exporter
      +-- Grafana
```

## Screenshot Walkthrough

### 1. Build the Docker Image

The application is packaged into an Nginx image using the `Dockerfile`. The screenshot shows Docker copying the React build files, applying the Nginx config, exposing port `80`, and tagging the image as `capstone-app:latest`.

![Docker image build output](<screenshots/Screenshot 2026-06-30 182038.png>)

The image is built from this Dockerfile:

```dockerfile
FROM nginx:stable-alpine
COPY build/ /web/data/
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

### 2. Test the Container Locally

The container was run locally on port `80` to confirm the app could be served by Nginx.

![Docker container run attempt](<screenshots/Screenshot 2026-06-30 182047.png>)

During testing, the Nginx logs showed a configuration syntax error. This was useful because it confirmed the container was starting and reading the custom Nginx config, but the config needed to be corrected.

![Nginx configuration error](<screenshots/Screenshot 2026-06-30 182056.png>)

The fixed Nginx config serves the React build directory and falls back to `index.html` for client-side routes.

![Nginx config in editor](<screenshots/Screenshot 2026-06-30 183152.png>)

After the fix, the OnlineShop app loaded successfully at `localhost`.

![OnlineShop running on localhost](<screenshots/Screenshot 2026-06-30 183121.png>)

### 3. Push the Image to Docker Hub

After the local image worked, it was pushed to Docker Hub. The repository shows the `v1` image tag being available.

![Docker Hub image tag](<screenshots/Screenshot 2026-06-30 184847.png>)

### 4. Run with Docker Compose

Docker Compose was used to run the web container. The screenshot shows the `web_1` container starting and Nginx becoming ready.

![Docker Compose startup logs](<screenshots/Screenshot 2026-07-01 125414.png>)

The Nginx access logs confirm the browser requested the React app files from `localhost`.

![Nginx access logs](<screenshots/Screenshot 2026-07-01 125445.png>)

The Compose setup later expanded to include the local monitoring stack:

```yaml
services:
  web:
    image: joelrobinson791/capstone-app:v1
    networks:
      - monitoring
    ports:
      - "80:80"

  grafana:
    image: grafana/grafana:nightly-slim
    networks:
      - monitoring
    ports:
      - "3000:3000"

  prometheus:
    image: prom/prometheus:latest
    networks:
      - monitoring
    ports:
      - "9090:9090"
    volumes:
      - ./prom.yml:/etc/prometheus/prometheus.yml

  blackbox-exporter:
    image: ubuntu/blackbox-exporter:0.28-26.04_stable
    networks:
      - monitoring
    ports:
      - "9115:9115"

networks:
  monitoring:
    external: true
```

## Jenkins CI/CD Setup

### 5. Configure a Multibranch Pipeline

Jenkins was configured as a multibranch pipeline so it could detect and run builds from the repository branches.

![Jenkins multibranch configuration](<screenshots/Screenshot 2026-07-02 143906.png>)

GitHub credentials were added in Jenkins so the pipeline could access the repository.

![Jenkins GitHub credentials](<screenshots/Screenshot 2026-07-02 144429.png>)

The build configuration was set to use the repository `Jenkinsfile`.

![Jenkinsfile build configuration](<screenshots/Screenshot 2026-07-02 144959.png>)

The pipeline was configured to build both `main` and `dev` branches.

![Jenkins branches to build](<screenshots/Screenshot 2026-07-02 145008.png>)

The multibranch trigger section was reviewed while setting up branch scanning.

![Jenkins multibranch trigger](<screenshots/Screenshot 2026-07-02 145723.png>)

### 6. Add and Fix the Jenkinsfile

The Jenkinsfile was added and committed to the repository.

![Jenkinsfile committed](<screenshots/Screenshot 2026-07-02 181526.png>)

GitHub shows both `dev` and `main` branches in the repository.

![GitHub dev and main branches](<screenshots/Screenshot 2026-07-02 183216.png>)

The first Jenkins run exposed a Groovy syntax issue in the Jenkinsfile.

![Jenkins Groovy syntax error](<screenshots/Screenshot 2026-07-02 181511.png>)

After fixing the Jenkinsfile, the pipeline started running and reached the branch check stage.

![Jenkins pipeline branch check](<screenshots/Screenshot 2026-07-02 183200.png>)

Another pipeline run found a shell substitution issue during the image build and push stage.

![Jenkins bad substitution error](<screenshots/Screenshot 2026-07-02 191114.png>)

The deployment stage also exposed SSH script formatting issues, including unexpected redirection and EOF handling errors.

![Jenkins SSH redirection error](<screenshots/Screenshot 2026-07-02 191640.png>)

![Jenkins EOF command error](<screenshots/Screenshot 2026-07-02 191926.png>)

The Jenkins build history shows several failed runs while the pipeline was being debugged.

![Jenkins failed build history](<screenshots/Screenshot 2026-07-02 192151.png>)

After the initial fixes, Jenkins successfully pulled the Docker image and completed the deployment stage.

![Jenkins successful deployment](<screenshots/Screenshot 2026-07-02 192208.png>)

The deployed OnlineShop app was then reachable from the EC2 public IP address.

![OnlineShop deployed on EC2](<screenshots/Screenshot 2026-07-02 192309.png>)

### 7. Redo Jenkins Success Evidence

For the redo, the Jenkinsfile was updated so the pipeline clearly detects `origin/dev` and `origin/main`. The `dev` branch builds and pushes the public development image, then pulls and deploys that image on the EC2 instance.

![Jenkins dev branch detected](<screenshots/Screenshot 2026-07-09 130052.png>)

The `dev` deployment console output shows the image being pulled from `joelrobinson791/capstone-app-dev`, the old container being stopped and removed if present, a new container being started, and the pipeline ending with `Finished: SUCCESS`.

![Jenkins dev deployment successful](<screenshots/Screenshot 2026-07-09 130103.png>)

The `main` branch was promoted using a no-fast-forward merge so Jenkins receives a new `main` commit hash and starts a production build.

![No fast-forward merge pushed to main](<screenshots/Screenshot 2026-07-09 130351.png>)

The `main` branch console output shows Jenkins checking out `origin/main` and using the corrected branch detection.

![Jenkins main branch detected](<screenshots/Screenshot 2026-07-09 130424.png>)

Because the production Docker Hub repository is private, the EC2 deploy step logs in to Docker Hub before pulling `joelrobinson791/capstone-app`. The final console output shows the image pull, container replacement, and `Finished: SUCCESS`.

![Jenkins main deployment successful](<screenshots/Screenshot 2026-07-09 130432.png>)

## AWS EC2 Deployment

Docker was installed and enabled on the EC2 instance so Jenkins could deploy the container remotely.

![Docker setup on EC2](<screenshots/Screenshot 2026-07-02 183546.png>)

The latest deployment target is the running EC2 app server with public IP `34.192.210.74`.

![AWS EC2 app server running](<screenshots/Screenshot 2026-07-09 130714.png>)

The Jenkins deployment stage performs these actions on the server:

1. Pulls the new image from Docker Hub.
2. Stops the old `capstone-app` container if it exists.
3. Removes the old container if it exists.
4. Runs the new image on port `80`.

The deployment target shown in the Jenkinsfile is:

```text
34.192.210.74
```

After the successful Jenkins run, the OnlineShop app was reachable from the EC2 public IP.

![OnlineShop available on EC2](<screenshots/Screenshot 2026-07-09 130735.png>)

## Local Monitoring Setup

### 8. Start Prometheus, Grafana, and Blackbox Exporter Locally

Because of AWS cost considerations, monitoring was demonstrated locally instead of hosting Prometheus and Grafana in AWS. The app image was run alongside the monitoring tools inside a local Docker environment.

The running containers include the web app, Prometheus, Grafana, and Blackbox Exporter.

![Local monitoring containers](<screenshots/Screenshot 2026-07-07 175759.png>)

Blackbox Exporter was pulled locally and added to the monitoring setup.

![Blackbox Exporter image pull](<screenshots/Screenshot 2026-07-07 175813.png>)

The full local monitoring stack can be started with:

```bash
docker network create monitoring
docker compose up -d
```

Use these URLs locally:

```text
Application:       http://localhost
Grafana:           http://localhost:3000
Prometheus:        http://localhost:9090
Blackbox Exporter: http://localhost:9115
```

### 9. Confirm Blackbox Exporter

Blackbox Exporter is available on `localhost:9115`.

![Blackbox Exporter homepage](<screenshots/Screenshot 2026-07-07 181418.png>)

After probing the app, Blackbox Exporter shows successful checks for the `http_2xx` module against `http://web:80`.

![Blackbox successful probes](<screenshots/Screenshot 2026-07-07 190409.png>)

### 10. Confirm Prometheus

Prometheus is available on `localhost:9090` and is used as the metrics source for the monitoring setup.

![Prometheus query page](<screenshots/Screenshot 2026-07-07 181427.png>)

The Prometheus config in `prom.yml` uses Blackbox Exporter to check the local web container:

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
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target

      - source_labels: [__param_target]
        target_label: capstone

      - target_label: __address__
        replacement: blackbox-exporter:9115
```

### 11. Confirm Grafana

Grafana is available on `localhost:3000`.

![Grafana login page](<screenshots/Screenshot 2026-07-07 181436.png>)

Grafana was connected to Prometheus and used to visualize the `probe_success` metric for the `app-health` job.

![Grafana probe success metric](<screenshots/Screenshot 2026-07-07 191826.png>)

The graph shows `probe_success` staying at `1` while the web app is reachable.

### 12. Validate Failure Detection

The local `web` container was stopped to confirm that monitoring detects downtime.

![Stopping the local web container](<screenshots/Screenshot 2026-07-07 191940.png>)

After the app stopped, the Grafana graph dropped from `1` to `0`, showing that the monitoring stack detected the failed health probe.

![Grafana probe failure after app stop](<screenshots/Screenshot 2026-07-07 192006.png>)

The browser also confirmed that `localhost` was no longer reachable after stopping the container.

![Localhost refused connection](<screenshots/Screenshot 2026-07-07 192015.png>)

## CI/CD Flow

The Jenkins pipeline follows this process:

1. Detect the Git branch that triggered the build.
2. Read the short Git commit hash.
3. Choose the production or development Docker image name.
4. Build the Docker image.
5. Log in to Docker Hub from Jenkins using Jenkins credentials.
6. Push a unique image tag and a readable image tag.
7. SSH into the EC2 instance.
8. For `origin/main`, log in to Docker Hub from EC2 because the production repository is private.
9. Pull and run the new container.

The Jenkins pipeline expects these credential IDs:

```text
docker-hub-credentials
ssh-credentials
```

The image naming strategy is:

```text
origin/main: joelrobinson791/capstone-app
origin/dev:  joelrobinson791/capstone-app-dev
```

The branch deployment strategy is:

```text
origin/main: private production image, Docker login on EC2, deploy to EC2
origin/dev:  public development image, direct pull on EC2, deploy to EC2
```

## Local Run

Create the external Docker network if it does not already exist:

```bash
docker network create monitoring
```

Start the stack:

```bash
docker compose up -d
```

Check the running containers:

```bash
docker compose ps
```

Stop the stack:

```bash
docker compose down
```

## Manual Docker Build

Build the Docker image manually:

```bash
docker build -t joelrobinson791/capstone-app:v1 .
```

Or use the helper script:

```bash
./build-image.sh
```

## Manual Deployment

The helper script pulls and runs the selected image:

```bash
./deploy-instance.sh
```

Default image:

```text
joelrobinson791/capstone-app:v1
```

## Useful Commands

```bash
docker compose ps
docker compose logs web
docker compose logs prometheus
docker compose logs grafana
docker compose logs blackbox-exporter
```

Check the app:

```bash
curl http://localhost
```

Open Prometheus targets:

```text
http://localhost:9090/targets
```

Open Blackbox Exporter:

```text
http://localhost:9115
```

Open Grafana:

```text
http://localhost:3000
```

## Repository Files

```text
Dockerfile             Builds the Nginx image for the React app
nginx.conf             Serves the React build and supports client-side routing
docker-compose.yaml    Runs the app and local monitoring stack
prom.yml               Prometheus scrape configuration
Jenkinsfile            Jenkins CI/CD pipeline
build-image.sh         Manual Docker image build helper
deploy-instance.sh     Manual deployment helper
build/                 Production React build output
screenshots/           Project walkthrough screenshots
```
