# Contrato inteligente de Kipubank

## Descripción
Kipubank es un contrato inteligente que implementa un token local descentralizado (ETH) con propiedades de seguridad y límites predeterminados. El contrato permite a los usuarios depositar y eliminar el ETH y mantener el registro detallado de todas las transacciones. ## Características principales

### depósitos y devoluciones
- Eth Tank en bóveda personal
- Retorno restringido a la transacción
- Los depósitos globales limitan el banco
- Registro de operaciones detalladas

### Seguridad
- Un error personalizado detallado
- Restricciones variables sin cambios
-Pattern-Control Effect Interaction
- Medidas de seguimiento de acción

### límites y limitaciones
- Capacidad bancaria máxima: 10 ETH
- Límite de retiro: 1 ETH en una transacción
- Registro de depósitos y retiros para cada usuario

## Tecnologías Utilizadas
- Solidity ^0.8.19
- Hardhat
- Ethers.js
- TypeScript/JavaScript

## Estructura del Contrato

### Variables Inmutables
```solidity
address public immutable i_owner;         // Dirección del propietario
uint256 public immutable i_bankCap;       // Límite máximo del banco
uint256 public immutable i_maxWithdrawalPerTx; // Límite por retiro
```

### Mapeos y Estructuras
```solidity
struct UserInfo {
    uint256 balance;        // Balance del usuario
    uint256 depositCount;   // Número de depósitos
    uint256 withdrawalCount; // Número de retiros
}

mapping(address => UserInfo) private s_userInfo;
```

## Instrucciones de Despliegue

1. Clonar el repositorio
```bash
git clone https://github.com/Jayala101/kipu-bank.git
cd kipu-bank
```

2. Instalar dependencias
```bash
npm install
```

3. Configurar variables de entorno
Crear archivo `.env` con:
```env
SEPOLIA_RPC_URL=tu_url_de_sepolia
PRIVATE_KEY=tu_clave_privada
ETHERSCAN_API_KEY=tu_api_key_de_etherscan
```

4. Compilar el contrato
```bash
npm run compile
```

5. Desplegar en Sepolia
```bash
npm run deploy:sepolia
```

## Cómo Interactuar con el Contrato

### Depósito de ETH
```javascript
// Depositar 1 ETH
await kipuBank.deposit({ value: ethers.parseEther("1.0") });
```

### Retiro de ETH
```javascript
// Retirar 0.5 ETH
await kipuBank.withdraw(ethers.parseEther("0.5"));
```

### Consulta de Información
```javascript
// Obtener información del usuario
const userInfo = await kipuBank.getUserInfo("dirección_del_usuario");
console.log("Balance:", ethers.formatEther(userInfo.balance), "ETH");
console.log("Número de depósitos:", userInfo.depositCount.toString());
console.log("Número de retiros:", userInfo.withdrawalCount.toString());
```