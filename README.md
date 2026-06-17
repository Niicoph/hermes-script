# hermes-script
 
> Build and run Hermes with Microsoft Teams integration.
 
---
 
## Requisitos previos
 
- Git instalado en la VM
- Ubuntu 24.04 LTS Minimal (o superior)
---
 
## Instalación
 
### 1. Clonar el repositorio
 
```bash
git clone https://github.com/Niicoph/hermes-script.git
cd hermes-script
```
 
### 2. Ejecutar el script de inicialización
 
```bash
sudo bash startup.sh
```
 
### 3. Levantar el contenedor
 
```bash
sudo docker run -d \
  --name hermes-gateway \
  --restart unless-stopped \
  --network host \
  -v ~/.hermes:/opt/data \
  -e HERMES_UID=0 \
  -e HERMES_GID=0 \
  hermes-agent-teams:latest \
  gateway run
```
 
---
 
## Configuración de Hermes
 
### 4. Ingresar al contenedor
 
```bash
sudo docker exec -it hermes-gateway /bin/bash
```
 
### 5. Ejecutar el asistente de configuración
 
```bash
hermes setup
```
 
Seguir estos pasos en el asistente:
 
| Paso | Opción a seleccionar |
|------|----------------------|
| Tipo de setup | `Full Setup` |
| Proveedor LLM | _(seleccionar según preferencia)_ |
| Modo de instalación | `Keep Current (local)` |
| Gateway | `Microsoft Teams` |
 
### 6. Ingresar credenciales de Azure
 
Cuando se soliciten, ingresar los siguientes valores de tu **Azure Bot Service**:
 
```
CLIENT_ID      = <tu client id>
CLIENT_SECRET  = <tu client secret>
TENANT_ID      = <tu tenant id>
```
 
### 7. Reiniciar el gateway
 
Confirmar el reinicio cuando se solicite: `Y`
 
Omitir el resto de las opciones.
 
---
 
## Exposición pública con ngrok
 
Para que Azure Bot Service pueda alcanzar el gateway local, se necesita un túnel HTTPS.
 
### 8. Instalar ngrok
 
```bash
curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
  | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
  | sudo tee /etc/apt/sources.list.d/ngrok.list && \
sudo apt update && sudo apt install ngrok
```
 
### 9. Configurar el token de autenticación
 
```bash
ngrok config add-authtoken <YOUR_TOKEN>
```
 
> Obtener el token en [dashboard.ngrok.com](https://dashboard.ngrok.com)
 
### 10. Iniciar el túnel
 
```bash
ngrok http 3978
```
 
### 11. Registrar la URL en Azure Bot Service
 
Copiar la URL generada por ngrok y configurarla como **Messaging Endpoint** en tu Azure Bot Service:
 
```
https://<tu-subdominio>.ngrok-free.app/api/messages
```
 
---
 
## Opcional: ngrok como servicio systemd
 
Para que ngrok persista entre reinicios, configurarlo como un servicio del sistema:
 
```bash
# Crear el archivo de servicio
sudo tee /etc/systemd/system/ngrok.service > /dev/null <<EOF
[Unit]
Description=ngrok tunnel
After=network.target
 
[Service]
ExecStart=/usr/local/bin/ngrok http 3978 --log=stdout
Restart=on-failure
User=$USER
 
[Install]
WantedBy=multi-user.target
EOF
 
# Habilitar e iniciar el servicio
sudo systemctl daemon-reload
sudo systemctl enable ngrok
sudo systemctl start ngrok
```
 
---
 
## Resumen del flujo
 
```
VM local
  └── Docker (hermes-gateway) :3978
        └── ngrok → URL pública HTTPS
                      └── Azure Bot Service → Microsoft Teams
```
































































































# hermes-script 

Build and run Hermes with Microsoft Teams   

- Tener instalado GIT en la VM
- Utilizar Ubuntu 26.04 LTS Minimal

1- git clone https://github.com/Niicoph/hermes-script.git
2- cd /hermes-script
3- sudo bash startup.sh 
4- ejecutar sudo docker run -d \
      --name hermes-gateway \
      --restart unless-stopped \
      --network host \
      -v ~/.hermes:/opt/data \
      -e HERMES_UID=0 \
      -e HERMES_GID=0 \
      hermes-agent-teams:latest \
      gateway run

5- Ingresar al contenedor: sudo docker exec -it hermes-gateway /bin/bash
6- ejecutar hermes setup
7- Select "Full Setup" 
8- Select LLM provider 
9- Modo de instalacion, elegir -> Keep Current (local) 
10- Gateway -> Microsoft Teams 
   - CLIENT_ID
   - CLIENT_SECRET
   - TENANT_ID
11- Restart the gateway to pick up changes: Y
12- Skip everything else

14- instalar ngrok: 

curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list && \
sudo apt update && sudo apt install ngrok

15- Agregar token

ngrok config add-authtoken <YOUR_TOKEN>

16- Ejecutar ngrok http 3978

17- tomar url y reemplazar en ABS (azure bot service) -> https://url.ngrok-free.dev/api/messages

18 - opcional
ejecutar ngrok como systemd para que persista

