# Terraformación en Azure con Azure DevOps

Esta es una configuración funcional para habilitar a Azure DevOps para la creación de servicios de nube en Azure.

Esta configuración deberá de adecuarse a las políticas de seguridad y gobierno de nube de la organización donde se pretenda utilizar.

## Prerrequisitos

1. Inquilino Azure con privilegios de "Administrador Global"
1. Suscripción Azure con privilegios de "Propietario"
1. Inquilino Azure DevOps con privilegios de "Administrador de la Colección de Proyectos"
1. Terraform v0.13.5
   * Proveedor de Azure v2.34.0
   * Proveedor de Azure DevOps v0.0.1

## Flujo de configuración

1. Terraformación de los servicios Azure base
1. Transferencia del estado local Terraform a una Cuenta de Almacenamiento de Azure
1. Reconfiguración del "*backend*" de Terraform
1. Configuración de privilegios del nodo de Terraform en la suscripción de Azure
1. Configuración de privilegios del nodo de Terraform en el inquilino de Azure
1. Crear canalización CI en Azure DevOps

### Terraformación de los servicios Azure base

El paso inicial en esta configuración es ejecutar los scripts de cableado ("*bootstrapping*") que se encuentran en el directorio de scripts/bootstrapping de este repositorio.

Estos scripts tienen que ejecutarse de manera local con Terraform.

Antes de ejecutar estos scripts se tiene que modificar el archivo terraform-01-custom-data.sh

Línea 14:

```
./config.sh --unattended --url <URL del inquilino Azure DevOps> --auth pat --token <PAT de Azure DevOps> --pool 'Terraform' --agent 'Terraform 01' --replace --work /home/vsts/work --acceptTeeEula
```

Donde:

\<URL del inquilino Azure DevOps>: Es la URL del inquilino de Azure DevOps que vamos a configurar (ej. https://dev.azure.com/tuinquilino)  
\<PAT de Azure DevOps>: Es el "*Personal Access Token*" de Azure DevOps con ámbito en "***Agent Pools + Read & manage***"

Posterior a esta modificación el comando que se tiene que ejecutar es el siguiente:

```
terraform plan -var-file="variables.tfvars" -var 'provider-org-service-url=https://dev.azure.com/<Nombre del inquilino de Azure DevOps>' -var 'provider-personal-access-token=<PAT de Azure DevOps>' -var 'linux-virtual-machine-01-admin-username=<Nombre de usuario administrador>' -var 'linux-virtual-machine-01-admin-password=<Contraseña de administrador>'
```

Donde:

\<Nombre del inquilino de Azure DevOps>: Es el nombre del inquilino de Azure DevOps que se va a configurar (ej. tuinquilino)  
\<PAT de Azure DevOps>: Es el "*Personal Access Token*" de Azure DevOps con ámbito en "***Agent Pools + Read & manage***"  
\<Nombre de usuario administrador>: Nombre de usuario administrador de la VM con Terraform  
\<Contraseña de administrador>: Contraseña de administrador de la VM con Terraform

### Transferencia del estado local Terraform a una Cuenta de Almacenamiento de Azure

Una ves que los servicios de nube base se hayan creado correctamente, se tiene que proceder al respaldo del estado de Terraform en la Cuenta de Almacenamiento creada.

Los pasos son los siguiente:

1. Localizar el directorio de trabajo actual donde se creo el estado de Terraform.
1. Navegar al portal de Azure
1. Localizar el grupo de recursos que contiene la Cuenta de Almacenamiento y acceder al mismo
1. Acceder a la Cuenta de Almacenamiento
1. Navegar la opción de **Contenedores** en el menú de **Blob Service**
1. Crear un contenedor (ej. states)
1. Acceder al contenedor
1. Cargar el archivo de estado Terraform al contenedor

### Reconfiguración del "*backend*" de Terraform

Una vez que el estado de Terraform ha sido cargado a la Cuenta de Almacenamiento se tiene que proceder a la reconfiguración del backend de Terraform con el propósito de utilizar el estado Terraform cargado como un estado remoto Terraform.

Los pasos para realizar la modificación son los siguientes:

1. Establecer los valores de las variables del backend Terraform en el archivo scripts/bootstrapping/environments/backend.de.tf
1. Habilitar el contenido del archivo backend.tf (descomentar contenido)
1. Reinicializar Terraform para establecer la nueva configuración de estado remoto Terraform
1. Realizar una prueba de planeación de creación de servicios Azure (terraform plan)

Para el paso número 2:

```
terraform init -backend-config="environments/backend.de.tf"
```

> TIP  
> En caso de no optar por utilizar este archivo se pueden pasar las variables de configuración del backend Terraform en el formato -backend-config="KEY=VALUE" (por cada variable a pasar).

### Configuración de privilegios del nodo de Terraform en la suscripción de Azure

El nodo de Terraform debe de poder crear recursos en la suscripción de Azure, para esto hay que asignar esos permisos a la Identidad Administrada generada para la VM.

Los pasos para asignar los privilegios necesarios son:

1. Navegar al portal de Azure
1. Localizar el grupo de recursos que contiene la VM de Terraform y acceder a la misma
1. Acceder a la Cuenta de Almacenamiento
1. Navegar la opción de **Identidad** en el menú de **Configuración**
1. Hacer clic en el botón "Asignaciones de roles de Azure"
1. Seleccionar la suscripción donde la VM tendrá privilegios
1. Hacer clic en el enlace "Agregar asignación de roles (versión preliminar)"
1. Seleccionar el ambito de los privilegios
1. Seleccionar el rol de la VM
1. Guardar la configuración

> TIP  
> Para que la VM de Terraform sea capaz de crear un amplio catalogo de recursos el ámbito deberá de ser Suscripción al momento de seleccionar el ámbito durante la adición de asignación de roles (versión preliminar).

> TIP  
> Para que la VM de Terraform tenga los privilegios de poder crear un amplio catalogo de recursos el rol deberá de ser Propietario al momento de seleccionar el rol durante la adición de asignación de roles (versión preliminar).

### Configuración de privilegios del nodo de Terraform en el inquilino de Azure

### Crear canalización CI en Azure DevOps