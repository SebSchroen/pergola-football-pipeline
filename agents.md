Here’s a structured `agents.md` file that outlines the do’s and don’ts of creating a `pergola.yaml` project manifest, based on the provided documentation:

---

# **Do’s and Don’ts of Creating a `pergola.yaml` Project Manifest**

This guide provides best practices and common pitfalls to avoid when creating a `pergola.yaml` (or `pergola.yml`) project manifest for the Pergola platform.

---

## **Do’s**

### **1. File Naming and Placement**
- **Do** place the manifest file in the **root folder** of your source tree.
- **Do** use one of the following filenames:
  - `pergola.yaml` (recommended)
  - `pergola.yml`
  - `pergola.json` (if using JSON format).

### **2. Versioning**
- **Do** specify the `version` field at the top of the manifest. Currently, only `v1` is supported.
  ```yaml
  version: v1
  ```

### **3. Components**
- **Do** define at least **one component** in your manifest. A component is the smallest deployable unit (e.g., a service, database, or job).
- **Do** use **unique names** for components. Allowed characters: lowercase letters (`a-z`), numbers (`0-9`), and hyphens (`-`). The name must start with a letter and cannot end with a hyphen.
  ```yaml
  components:
    - name: web-api  # Valid
    - name: db       # Valid
    - name: my-component-1  # Valid
  ```
- **Do** ensure each component has either a `docker.file` (path to a Dockerfile) or a `docker.image` (pre-built container image).
  ```yaml
  components:
    - name: web-api
      docker:
        file: Dockerfile  # Path to Dockerfile
    - name: db
      docker:
        image: postgres:16  # Pre-built image
  ```

### **4. Docker Configuration**
- **Do** specify a **build context** if your Dockerfile is not in the root directory.
  ```yaml
  docker:
    file: Dockerfile
    build-context: ./subdirectory
  ```
- **Do** use **build arguments** if your Dockerfile requires them. Ensure values are passed as strings (e.g., `"true"` instead of `true`).
  ```yaml
  docker:
    file: Dockerfile
    build-args:
      - name: ENABLE_FEATURE
        value: "true"
  ```
- **Do** leverage **pre-defined build arguments** for dynamic values like commit IDs or timestamps:
  ```yaml
  docker:
    file: Dockerfile
    build-args:
      - name: BUILD_ID
        value: "$(BUILD_NAME)"
      - name: COMMIT_HASH
        value: "$(GIT_COMMIT_ID)"
  ```

### **5. Environment Variables**
- **Do** use **`config-ref`** for environment variables that should vary across stages (e.g., `DEV`, `LIVE`).
  ```yaml
  env:
    - name: DB_PASSWORD
      config-ref: db_password  # Resolved at release time
  ```
- **Do** provide **default values** for optional configuration references:
  ```yaml
  env:
    - name: LOG_LEVEL
      config-ref: log_level
      value: "info"  # Default if not provided
  ```
- **Do** reference other components using **`component-ref`** to dynamically resolve hostnames:
  ```yaml
  env:
    - name: DB_HOST
      component-ref: db  # Resolves to the hostname of the 'db' component
  ```

### **6. Files**
- **Do** use **`config-ref`** to inject configuration files from Pergola’s configuration management:
  ```yaml
  files:
    - path: /etc/config.json
      config-ref: app-config.json
  ```
- **Do** embed small static files directly in the manifest using **`content`**:
  ```yaml
  files:
    - path: /var/lib/static.xml
      content: |
        <?xml version="1.0"?>
        <config>...</config>
  ```

### **7. Storage**
- **Do** define **persistent storage** for databases or stateful components:
  ```yaml
  storage:
    - name: pgdata
      path: /var/lib/postgresql/data
      size: 50Gi  # Supports suffixes like M, G, T, Mi, Gi, Ti
  ```
- **Do** use **ephemeral storage** (`type: temporary` or `type: memory`) for caching or shared memory:
  ```yaml
  storage:
    - name: cache
      path: /tmp/cache
      size: 1Gi
      type: temporary
  ```

### **8. Ports and Ingress**
- **Do** expose ports that your component listens on:
  ```yaml
  ports:
    - 8080
    - 5432
  ```
- **Do** define **ingress rules** to expose HTTP/HTTPS endpoints:
  ```yaml
  ingresses:
    - host: api
      path: /v1
      port: 8080
  ```

### **9. Scaling**
- **Do** set **scaling boundaries** if your component should run multiple instances:
  ```yaml
  scaling:
    min: 2  # Minimum instances
    max: 5  # Maximum instances
  ```

### **10. Scheduling**
- **Do** use **cron expressions** for regular jobs:
  ```yaml
  scheduled: "0 2 * * *"  # Runs daily at 2 AM UTC
  ```
- **Do** use **`@release`** for one-time jobs per release:
  ```yaml
  scheduled: "@release"
  ```

### **11. Security**
- **Do** run components as **non-root users** where possible:
  ```yaml
  user: 1001  # Run as UID 1001
  ```
- **Do** specify **resource limits** (CPU/memory) to avoid overconsumption:
  ```yaml
  resources:
    cpu: 500m  # 0.5 CPU
    memory: 2Gi
  ```

### **12. Validation**
- **Do** validate your manifest locally before committing:
  ```bash
  pergola validate
  ```

---

## **Don’ts**

### **1. File Naming and Structure**
- **Don’t** use unsupported filenames (e.g., `manifest.yaml`, `config.yml`).
- **Don’t** place the manifest in a subdirectory; it must be in the root.

### **2. Component Naming**
- **Don’t** use uppercase letters, spaces, or special characters in component names.
- **Don’t** start or end names with hyphens (e.g., `-web-api` or `web-api-`).

### **3. Docker Configuration**
- **Don’t** omit the `docker` field; every component must have either a `file` or `image`.
- **Don’t** use unquoted non-string values in `build-args` (e.g., `value: 1234` should be `value: "1234"`).
- **Don’t** assume default build contexts; explicitly define `build-context` if needed.

### **4. Environment Variables**
- **Don’t** hardcode sensitive values (e.g., passwords) in the manifest. Use `config-ref` instead.
- **Don’t** create circular references between environment variables.
- **Don’t** reference undefined components in `component-ref`.

### **5. Files**
- **Don’t** embed large binary files directly in the manifest. Use `config-ref` or external storage.
- **Don’t** use `content` for files that change frequently; prefer `config-ref`.

### **6. Storage**
- **Don’t** shrink the size of **persistent storage** after creation; it’s not supported.
- **Don’t** assume ephemeral storage (`type: temporary` or `type: memory`) persists across restarts.

### **7. Ports and Ingress**
- **Don’t** expose unnecessary ports; only list those your component actively uses.
- **Don’t** define duplicate `host`+`path` combinations in ingress rules.

### **8. Scaling**
- **Don’t** set `min` or `max` to `0`; components must have at least one instance.
- **Don’t** rely on scaling without defining `resources`; unpredictable performance may occur.

### **9. Scheduling**
- **Don’t** use invalid cron expressions (e.g., `"* *"`). Validate them [here](https://crontab.guru/).
- **Don’t** assume `@release` jobs run more than once per release unless retries are configured.

### **10. Security**
- **Don’t** run components as `root` unless absolutely necessary.
- **Don’t** omit resource limits (`cpu`/`memory`) for production workloads.

### **11. General**
- **Don’t** mix YAML and JSON formats in the same manifest.
- **Don’t** commit unvalidated manifests; always run `pergola validate`.

---

## **Example Manifest**
Here’s a well-structured example:
```yaml
version: v1

components:
  - name: web-api
    docker:
      file: Dockerfile
      build-context: .
      build-args:
        - name: ENV
          value: "production"
    env:
      - name: DB_HOST
        component-ref: db
      - name: API_KEY
        config-ref: api_key
    ports:
      - 8080
    ingresses:
      - host: api
        path: /v1
        port: 8080
    scaling:
      min: 2
      max: 4

  - name: db
    docker:
      image: postgres:16
    env:
      - name: POSTGRES_PASSWORD
        config-ref: db_password
    storage:
      - name: pgdata
        path: /var/lib/postgresql/data
        size: 50Gi
    ports:
      - 5432
```

---

## **Additional Resources**
- [Pergola Project Manifest Documentation][1]
- [Pergola CLI Reference](https://docs.pergola.cloud/docs/cli)
- [Cron Expression Validator](https://crontab.guru/)

[1]: https://docs.pergola.cloud/docs/reference/project-manifest

---

This `agents.md` file can be placed in your project’s documentation directory (e.g., `/docs`) to guide your team.