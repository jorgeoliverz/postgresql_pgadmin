# PostgreSQL + pgAdmin con Docker Compose

Entorno local con una base de datos PostgreSQL y pgAdmin para administrarla.

## Requisitos

- Docker y Docker Compose

## Configuración

Toda la configuración se lee del fichero `.env` (no se sube al repositorio). Copia la plantilla y ajusta los valores si quieres:

```bash
cp .env.example .env
```

| Variable                  | Descripción                        | Valor de ejemplo   |
| ------------------------- | ---------------------------------- | ------------------ |
| `POSTGRES_USER`           | Usuario de PostgreSQL              | `postgres`         |
| `POSTGRES_PASSWORD`       | Contraseña de PostgreSQL           | `postgres`         |
| `POSTGRES_DB`             | Base de datos que se crea al inicio| `postgres`         |
| `PGADMIN_DEFAULT_EMAIL`   | Email para entrar en pgAdmin       | `admin@admin.com`  |
| `PGADMIN_DEFAULT_PASSWORD`| Contraseña para entrar en pgAdmin  | `admin`            |

Si falta alguna variable, `docker compose` no arranca y avisa de cuál falta.

> **Nota:** `POSTGRES_USER`, `POSTGRES_PASSWORD` y `POSTGRES_DB` solo se aplican la primera vez que se crea el volumen. Si los cambias después, hay que borrar el volumen con `docker compose down -v` (se pierden los datos).

## Uso

```bash
docker compose up -d      # levantar
docker compose logs -f    # ver logs
docker compose down       # parar
docker compose down -v    # parar y borrar los datos
```

Servicios:

| Servicio   | Puerto en tu máquina | Descripción              |
| ---------- | -------------------- | ------------------------ |
| PostgreSQL | `5432`               | Base de datos            |
| pgAdmin    | `5050`               | Interfaz web de gestión  |

Los datos persisten en los volúmenes `postgres_data` y `pgadmin_data`.

## Conectarse a la base de datos

### Desde pgAdmin

1. Abre http://localhost:5050 y entra con `PGADMIN_DEFAULT_EMAIL` / `PGADMIN_DEFAULT_PASSWORD`.
2. Click derecho en **Servers → Register → Server...**
3. Pestaña **General**: pon un nombre cualquiera (ej. `local`).
4. Pestaña **Connection**:
   - **Host name/address:** `postgres` (nombre del servicio en Compose; pgAdmin corre dentro de la misma red de Docker, así que **no** uses `localhost`)
   - **Port:** `5432`
   - **Maintenance database:** el valor de `POSTGRES_DB`
   - **Username:** `POSTGRES_USER`
   - **Password:** `POSTGRES_PASSWORD`
5. **Save**.

### Desde VS Code

Instala una extensión de PostgreSQL, por ejemplo **PostgreSQL** (de Microsoft, `ms-ossdata.vscode-pgsql`), y crea una conexión con:

- **Host:** `localhost` (aquí sí, porque te conectas desde tu máquina al puerto publicado)
- **Port:** `5432`
- **Database:** `POSTGRES_DB`
- **User:** `POSTGRES_USER`
- **Password:** `POSTGRES_PASSWORD`

### Desde la terminal

```bash
docker compose exec postgres psql -U postgres -d postgres
```

O con un cliente `psql` instalado en tu máquina:

```bash
psql -h localhost -p 5432 -U postgres -d postgres
```
