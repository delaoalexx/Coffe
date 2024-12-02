# API pay-me (aka Coffe)

  

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)

  
  

## Related

  

pay-me: https://github.com/Cesura012/pay-me

more: https://rentry.org/apicoffe


## Descripción General

  

Coffe es una API diseñada para pay-me, una aplicación web que simula un sistema de pagos tipo PayPal. Permite a los usuarios registrarse, hacer transferencias y ver su historial de transacciones.

  

## Tecnologías Utilizadas

  

- Node.js

- MySQL

- JavaScript

- Railway (Deployment [Soon])

  

## Estructura de la Base de Datos

  

- Soon

  
  

### Requerimientos

  

- [Node.js](https://nodejs.org/en/)

- [MySQL](https://www.mysql.com/)

  

### Instalación

  

1. Clonar el repositorio

  

```

git clone https://github.com/delaoalexx/Coffe.git

```

  

2. Instalar dependencias

  
```
npm install express body-parser dotenv mysql2
```
  

3. Crear la base de datos

```
CREATE DATABASE apiPayMe;
	
USE apiPayMe;
...
```

5. Ejecutar la aplicación

```
npm run start
```

## Configuración del Proyecto

  
[soon]
### Variables de Entorno (.env)

  

```

DB_HOST=localhost

DB_USER=root

DB_PASSWORD=your_password

DB_NAME=apiPayMe

DB_PORT=port_example_3306

PORT=3001

```

## ENDPOINTS

### Usuarios

###  CREAR USER
#### POST /localhost:3001/users
Crea una nueva cuenta bancaria.

```javascript
{

    "first_name": "geroge",

    "last_name": "smith",

    "email": "george@gmail.com",

    "password": "8digitspw"

}
```



## AUTENTICAR USER

#### POST /localhost:3001/login
LogIn 

```javascript
{

    "email": "george@gmail.com",

    "password": "8digitspw"

}
```

