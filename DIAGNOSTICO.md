# Diagnóstico: la extensión PostgreSQL de VS Code no conecta al contenedor

**Fecha:** 2026-09-13
**Síntoma:** la extensión **PostgreSQL** de Microsoft (`ms-ossdata.vscode-pgsql`) no consigue conectar a `localhost:5432` con las credenciales del `.env` (`postgres` / `postgres`).

## Resumen

El contenedor estaba perfectamente. El problema era un **conflicto de puerto**: en WSL había un **PostgreSQL 16 instalado con `apt`** (servicio `postgresql` activo) escuchando en `127.0.0.1:5432`. Al conectar a `localhost:5432`, tanto desde WSL como desde Windows, la conexión iba a ese servidor nativo, no al contenedor de Docker. Como el servidor nativo no tiene la contraseña `postgres` (usa autenticación `peer` por defecto), la extensión fallaba con error de autenticación.

## Pasos del diagnóstico

### 1. Revisar la configuración del proyecto

```bash
cat compose.yaml .env README.md
```

- `compose.yaml` publica `5432:5432` para `postgres` y `5050:80` para `pgadmin`.
- `.env` define `POSTGRES_USER=postgres`, `POSTGRES_PASSWORD=postgres`, `POSTGRES_DB=postgres`.
- El README indica conectar desde VS Code con `localhost:5432`, lo cual es correcto.

Conclusión: la configuración era coherente; no era un error de credenciales o de compose.

### 2. Comprobar que el contenedor está vivo y sano

```bash
docker compose ps
docker compose logs --tail 30 postgres
docker compose exec -T postgres pg_isready -h localhost -U postgres
```

- `postgres` → `Up (healthy)`, puertos `0.0.0.0:5432->5432/tcp`.
- Logs: `database system is ready to accept connections`.
- `pg_isready` dentro del contenedor → `accepting connections`.

Conclusión: el servidor del contenedor funciona. El fallo tenía que estar entre el cliente y el contenedor.

### 3. Ver quién escucha en el puerto 5432 en WSL

```bash
ss -ltnp | grep 5432
```

Resultado:

```
LISTEN 0 200 127.0.0.1:5432 0.0.0.0:*
```

Primera señal sospechosa: Docker Desktop normalmente publica en `0.0.0.0`/`*`, no solo en `127.0.0.1`. Y el backlog `200` es el valor por defecto de PostgreSQL, no del proxy de Docker.

### 4. Probar la conexión real con credenciales, desde dos sitios distintos

**Desde WSL (como lo haría la extensión):**

```bash
PGPASSWORD=postgres psql -h localhost -p 5432 -U postgres -d postgres -c 'select version();'
```

```
FATAL: password authentication failed for user "postgres"
```

**Desde dentro de la red de Docker (llegando seguro al contenedor):**

```bash
docker run --rm --network host -e PGPASSWORD=postgres postgres:18.6-alpine \
  psql -h 127.0.0.1 -U postgres -d postgres -c 'select current_user, current_database();'
```

```
 current_user | current_database
--------------+------------------
 postgres     | postgres
```

Conclusión clave: **la misma contraseña funciona contra el contenedor y falla contra `localhost:5432` de WSL**. Por tanto, lo que hay en `localhost:5432` de WSL **no es el contenedor**.

### 5. Identificar el servidor intruso

```bash
systemctl is-active postgresql      # → active
ls /etc/postgresql                  # → 16
pg_lsclusters
dpkg -l | grep -i postgres
```

```
Ver Cluster Port Status Owner    Data directory
16  main    5432 online postgres /var/lib/postgresql/16/main
```

Paquetes instalados: `postgresql`, `postgresql-16`, `postgresql-contrib`, `postgresql-common`, `postgresql-client-16`, ...

Conclusión: había un **PostgreSQL 16 nativo en WSL**, arrancado como servicio, ocupando `127.0.0.1:5432`.

### 6. Confirmar qué pasa en el lado Windows

Si VS Code corre en Windows (no en modo Remote-WSL), la extensión conecta al `localhost` de Windows. Comprobación:

```bash
netstat.exe -ano | grep ':5432'
powershell.exe -NoProfile -Command "Get-Process -Id 7912,25836 | Format-Table Id,ProcessName,Path"
```

```
TCP  0.0.0.0:5432    LISTENING  25836   → com.docker.backend.exe  (Docker Desktop)
TCP  127.0.0.1:5432  LISTENING  7912    → wslrelay.exe            (reenvío de puertos de WSL)
```

`wslrelay.exe` reenvía automáticamente a Windows los puertos en los que escucha WSL. Como el Postgres nativo de WSL escuchaba en `127.0.0.1:5432`, Windows tenía **dos** listeners en 5432, y `127.0.0.1` (más específico) gana sobre `0.0.0.0`. Es decir, **también desde Windows** `localhost:5432` iba al Postgres nativo de WSL, no a Docker.

## Diagrama del problema

```
VS Code (Windows) ──localhost:5432──► 127.0.0.1:5432  wslrelay.exe ──► PostgreSQL 16 nativo (WSL)  ✗ auth failed
                                      0.0.0.0:5432    com.docker.backend ──► contenedor postgres    (nunca llega)

Cliente en WSL ─────localhost:5432──► 127.0.0.1:5432  PostgreSQL 16 nativo (WSL)                    ✗ auth failed
```

## Solución aplicada

Desinstalar el PostgreSQL nativo de WSL, ya que solo se quiere usar el de Docker:

```bash
sudo systemctl stop postgresql
sudo systemctl disable postgresql
sudo apt purge -y postgresql postgresql-16 postgresql-contrib postgresql-common
sudo apt autoremove -y
sudo rm -rf /var/lib/postgresql /etc/postgresql /var/log/postgresql
```


## Segundo síntoma tras desinstalar: `Connection refused`

Tras quitar el Postgres nativo, la extensión pasó a dar:

```
connection to server at "127.0.0.1", port 5432 failed: Connection refused
```

### Diagnóstico

```bash
systemctl is-active postgresql     # → inactive (nativo eliminado)
docker compose ps                  # → postgres Up (healthy), 0.0.0.0:5432->5432/tcp
ss -ltnp | grep 5432               # → nada escuchando en 5432 dentro de WSL
netstat.exe -ano | grep :5432      # → 0.0.0.0:5432 com.docker.backend (Windows)
timeout 3 bash -c '</dev/tcp/127.0.0.1/5432'                      # WSL     → Connection refused
powershell.exe -c "(Test-NetConnection 127.0.0.1 -Port 5432).TcpTestSucceeded"  # Windows → True
ps aux | grep -c vscode-server     # → 16 (VS Code corre en modo Remote-WSL)
```

Conclusión: el puerto estaba publicado **solo en el lado Windows**, no dentro de WSL. Como VS Code corre en modo **Remote-WSL**, la extensión se conecta desde dentro de WSL, donde ya no había nadie en `127.0.0.1:5432`.

Causa: cuando Docker levantó el stack, el 5432 dentro de WSL lo tenía el Postgres nativo. En Linux, enlazar `0.0.0.0:5432` falla con `EADDRINUSE` si ya hay alguien en `127.0.0.1:5432`, así que Docker Desktop solo pudo publicar el puerto en Windows. Al eliminar el Postgres nativo el puerto quedó libre, pero el contenedor seguía con el enlace antiguo (`Up 19 minutes`, nunca se reinició).

### Solución

Reiniciar el stack para que Docker vuelva a publicar el puerto con el 5432 ya libre:

```bash
docker compose down && docker compose up -d
```

## Verificación

```bash
ss -ltnp | grep 5432
# LISTEN 0 4096 *:5432 *:*        ← ahora sí, el proxy de Docker (backlog 4096)

timeout 3 bash -c '</dev/tcp/127.0.0.1/5432' && echo ABIERTO
# ABIERTO

docker run --rm --network host -e PGPASSWORD=postgres postgres:18.6-alpine \
  psql -h 127.0.0.1 -U postgres -d postgres -c 'select version();'
# PostgreSQL 18.6 on x86_64-pc-linux-musl ... Alpine   ← la versión del contenedor

curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:5050/login
# 200                                                  ← pgAdmin accesible
```

Estado final: en `localhost:5432` solo está el contenedor, accesible desde WSL y desde Windows, con `postgres` / `postgres`.

> Nota: al purgar los paquetes se fue también `postgresql-client-16`, así que ya no hay `psql` en WSL. Para entrar por terminal: `docker compose exec postgres psql -U postgres -d postgres`. Si se quiere `psql` local: `sudo apt install postgresql-client-16` (solo cliente, no abre puertos).

## Lección

Cuando "no conecta" y el contenedor está `healthy`, comprobar **quién está realmente escuchando en el puerto** (`ss -ltnp`, `netstat.exe -ano`) y probar la conexión con credenciales desde varios puntos. Un servidor duplicado en el mismo puerto (instalación nativa, otro contenedor, otro proyecto) es una causa muy habitual de errores de autenticación "imposibles". Y tras liberar un puerto, **reiniciar el contenedor** que lo publica: Docker no vuelve a intentar el enlace por sí solo.
