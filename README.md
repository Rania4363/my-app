Pipeline DevSecOps complet avec intégration de la sécurité à chaque étape.

## 🏗️ Architecture

<img width="801" height="735" alt="image" src="https://github.com/user-attachments/assets/6b827bb6-f901-451f-ac19-3055a9ff618c" />


## 🛠️ Stack technique

| Outil | Rôle |
|-------|------|
| Jenkins | CI/CD Server |
| Maven | Build & Tests |
| SonarQube | Qualité du code |
| Trivy | Security Scan |
| Nexus | Image Registry |
| Kubernetes | Déploiement |
| Prometheus | Collecte métriques |
| Grafana | Dashboards |

## 📊 Monitoring

- Prometheus scrape `/actuator/prometheus`
- Grafana dashboard SpringBoot APM
- Node Exporter pour les métriques système

### Jenkins Pipeline

<img width="1600" height="758" alt="image" src="https://github.com/user-attachments/assets/5b84d6e8-917d-4db5-a9b8-e546c32d4fee" />

### Grafana Dashboard

<img width="1600" height="758" alt="image" src="https://github.com/user-attachments/assets/9530a222-d420-445b-94e2-6b7137b3190e" />
<img width="1600" height="760" alt="image" src="https://github.com/user-attachments/assets/1cf7f743-a633-4ca0-9a02-4c9ba10727c3" />

### SonarQube
<img width="1600" height="603" alt="image" src="https://github.com/user-attachments/assets/f41d40b1-d67f-47e1-a679-5065477c62e3" />


### Prometheus Targets
<img width="1600" height="760" alt="image" src="https://github.com/user-attachments/assets/709d8572-68ff-4b42-9dc3-901fda06b744" />

### Nexus Registry
<img width="1600" height="704" alt="image" src="https://github.com/user-attachments/assets/44a9aab8-bc40-409a-bb33-f6fafa6d3f6d" />
